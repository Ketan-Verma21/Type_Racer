// All game rules live here. Nothing in this file touches a socket directly
// (only broadcasts to a room through io), so it is easy to unit-test later.
const Game = require("../Models/Game");
const getSentence = require("../api/getSentence");
const { getIO } = require("../utils/io");
const { calculateWPM } = require("../utils/helpers");
const { clearGameTimers } = require("./timerService");
const { clearHistory } = require("./chatService");
const {
    MODES,
    TIME_LIMITS,
    LENGTH_WORDS,
    MAX_PLAYERS_LIMIT,
} = require("../config/constants");

// ───────────── queries on a game document ─────────────
const racersOf = (game) => game.players.filter((p) => !p.isSpectator);
const isFinished = (game, p) => p.currentWordIndex >= game.words.length;

// Should the race end right now?
const shouldEnd = (game) => {
    const racers = racersOf(game);
    if (racers.length === 0) return false;
    const active = racers.filter((p) => !p.isEliminated && !isFinished(game, p));
    if (active.length === 0) return true; // everyone finished or is out
    if (game.settings.mode === "sudden-death") {
        if (racers.some((p) => isFinished(game, p))) return true; // first to finish wins
        if (racers.length >= 2 && active.length <= 1) return true; // last one standing
    }
    return false;
};

// ───────────── lifecycle ─────────────
const createGame = async (socketId, nickname) => {
    let game = new Game();
    game.words = await getSentence(LENGTH_WORDS[game.settings.length]);
    game.players.push({ socketID: socketId, nickname, isPartyLeader: true });
    game = await game.save();
    return { game, player: game.players[0] };
};

// Lobby -> joins as a racer. Race started/finished -> joins as a spectator.
// Returns { error } or { game, player }.
const joinGame = async (gameId, socketId, nickname) => {
    let game = await Game.findById(gameId);
    if (!game) return { error: "Please enter a valid game id" };

    if (game.isJoin) {
        if (racersOf(game).length >= game.settings.maxPlayers) {
            return { error: "This room is full" };
        }
        game.players.push({ nickname, socketID: socketId });
    } else {
        game.players.push({ nickname, socketID: socketId, isSpectator: true });
    }
    game = await game.save();
    return { game, player: game.players[game.players.length - 1] };
};

// Host changes settings in the lobby. Returns the saved game, or null if not allowed.
const applySettings = async (gameId, playerId, settings) => {
    let game = await Game.findById(gameId);
    if (!game || !game.isJoin) return null;
    const me = game.players.id(playerId);
    if (!me || !me.isPartyLeader) return null;

    const s = game.settings;
    const racers = racersOf(game).length;
    const next = {
        mode: MODES.includes(settings.mode) ? settings.mode : s.mode,
        timeLimit: TIME_LIMITS.includes(Number(settings.timeLimit))
            ? Number(settings.timeLimit)
            : s.timeLimit,
        length: Object.keys(LENGTH_WORDS).includes(settings.length)
            ? settings.length
            : s.length,
        maxPlayers: Math.min(
            MAX_PLAYERS_LIMIT,
            Math.max(racers, parseInt(settings.maxPlayers) || s.maxPlayers)
        ),
    };
    const lengthChanged = next.length !== s.length;
    game.settings.mode = next.mode;
    game.settings.timeLimit = next.timeLimit;
    game.settings.length = next.length;
    game.settings.maxPlayers = next.maxPlayers;
    if (lengthChanged) game.words = await getSentence(LENGTH_WORDS[next.length]);
    return await game.save();
};

// A player submitted a word. Returns { game, finished } if something changed
// (so the caller should broadcast), or null if the input is ignored.
const processWord = async (gameId, socketId, userInput) => {
    let game = await Game.findById(gameId);
    if (!game || game.isJoin || game.isOver) return null;
    const player = game.players.find((p) => p.socketID === socketId);
    if (!player || player.isSpectator || player.isEliminated) return null;
    if (isFinished(game, player)) return null;

    const now = new Date().getTime();

    if (game.words[player.currentWordIndex] === userInput.trim()) {
        player.currentWordIndex += 1;
        const finished = isFinished(game, player);
        if (finished) player.WPM = calculateWPM(now, game.startTime, player);
        game = await game.save();
        return { game, finished };
    }

    // wrong word -> depends on the mode
    player.mistakes += 1;
    const mode = game.settings.mode;
    if (mode === "sudden-death") {
        player.isEliminated = true;
        player.WPM = calculateWPM(now, game.startTime, player);
    } else if (mode === "no-mistakes") {
        player.currentWordIndex = 0; // back to the start!
    } else {
        return null; // classic: ignored
    }
    game = await game.save();
    return { game, finished: false };
};

// Stop timers, fill in WPM for everyone still running, tell the room.
const endGame = async (gameId) => {
    clearGameTimers(gameId); // synchronous, so it can't run twice
    try {
        const io = getIO();
        let game = await Game.findById(gameId);
        if (!game || game.isOver) return;
        const endTime = new Date().getTime();
        racersOf(game).forEach((player) => {
            if (player.WPM == -1) {
                player.WPM = calculateWPM(endTime, game.startTime, player);
            }
        });
        game.isOver = true;
        game = await game.save();
        io.to(gameId).emit("updateGame", game);
        io.to(gameId).emit("done");
    } catch (e) {
        console.log(e);
    }
};

// Host starts another round in the same room. Returns the saved game or null.
const rematch = async (gameId, playerId) => {
    let game = await Game.findById(gameId);
    if (!game || !game.isOver) return null;
    const me = game.players.id(playerId);
    if (!me || !me.isPartyLeader) return null;

    clearGameTimers(gameId);
    game.words = await getSentence(LENGTH_WORDS[game.settings.length]);

    let slots = game.settings.maxPlayers;
    game.players.forEach((p) => {
        if (!p.isSpectator) slots--;
        p.currentWordIndex = 0;
        p.WPM = -1;
        p.isEliminated = false;
        p.mistakes = 0;
    });
    // spectators become racers while there is room
    game.players.forEach((p) => {
        if (p.isSpectator && slots > 0) {
            p.isSpectator = false;
            slots--;
        }
    });
    game.isJoin = true;
    game.isOver = false;
    game.startTime = undefined;
    return await game.save();
};

// A player left, or disconnected and never came back.
const removePlayer = async (gameId, playerId) => {
    try {
        const io = getIO();
        let game = await Game.findById(gameId);
        if (!game) return;
        game.players.pull(playerId);

        if (game.players.length === 0) {
            clearGameTimers(gameId);
            clearHistory(gameId);
            await Game.findByIdAndDelete(gameId);
            return;
        }
        if (!game.players.some((p) => p.isPartyLeader)) {
            const next = game.players.find((p) => !p.isSpectator) || game.players[0];
            next.isPartyLeader = true;
        }
        game = await game.save();
        io.to(gameId).emit("updateGame", game);

        if (!game.isJoin && !game.isOver && shouldEnd(game)) {
            await endGame(gameId);
        }
    } catch (e) {
        console.log(e);
    }
};

// Used by the reconnect handler: attach a new socket id to an existing player.
const reattachPlayer = async (gameId, playerId, socketId) => {
    const game = await Game.findById(gameId);
    const player = game && game.players.id(playerId);
    if (!player) return null;
    player.socketID = socketId;
    await game.save();
    return { game, player };
};

module.exports = {
    racersOf,
    shouldEnd,
    createGame,
    joinGame,
    applySettings,
    processWord,
    endGame,
    rematch,
    removePlayer,
    reattachPlayer,
};
