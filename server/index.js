const express = require("express");
const mongoose = require("mongoose");
const http = require("http");
const dotenv = require("dotenv");
dotenv.config();
const Game = require("./Models/Game");
const getSentence = require("./api/getSentence");

// Creating a Server
const app = express();
const server = http.createServer(app);
var io = require("socket.io")(server);

// Middleware
app.use(express.json());

//Connecting to MongoDB
const DB = process.env.MONGO_URL;

// ───────────────────────── helpers / in-memory state ─────────────────────────

// gameId -> { countdown, clock }  (the intervals running for that game)
const gameTimers = new Map();
// playerId -> timeout that removes a disconnected player after a grace period
const pendingLeaves = new Map();
const RECONNECT_GRACE_MS = 15000;
const GAME_SECONDS = 120;

const clearGameTimers = (gameId) => {
    const t = gameTimers.get(gameId);
    if (t) {
        clearInterval(t.countdown);
        clearInterval(t.clock);
        gameTimers.delete(gameId);
    }
};

const calculateTime = (time) => {
    let min = Math.floor(time / 60);
    let second = time % 60;
    return `${min}:${second < 10 ? "0" + second : second}`;
};

const calculateWPM = (endTime, startTime, player) => {
    const timeTaken = ((endTime - startTime) / 1000) / 60;
    let wordsTyped = player.currentWordIndex;
    const WPM = Math.floor(wordsTyped / timeTaken);
    return Number.isFinite(WPM) ? WPM : 0;
};

const allFinished = (game) =>
    game.players.length > 0 &&
    game.players.every((p) => p.currentWordIndex >= game.words.length);

// Finish the game: stop timers, fill in WPM for unfinished players, tell everyone.
const endGame = async (gameId) => {
    clearGameTimers(gameId); // synchronous, so it can't run twice
    try {
        let game = await Game.findById(gameId);
        if (!game || game.isOver) return;
        const endTime = new Date().getTime();
        game.players.forEach((player) => {
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

// Remove a player from a game (left, or disconnected and didn't come back).
const removePlayer = async (gameId, playerId) => {
    try {
        let game = await Game.findById(gameId);
        if (!game) return;
        game.players.pull(playerId);

        // nobody left -> delete the room and stop its timers
        if (game.players.length === 0) {
            clearGameTimers(gameId);
            await Game.findByIdAndDelete(gameId);
            return;
        }
        // the leader left -> promote the next player
        if (!game.players.some((p) => p.isPartyLeader)) {
            game.players[0].isPartyLeader = true;
        }
        game = await game.save();
        io.to(gameId).emit("updateGame", game);

        // everyone still here has already finished -> end the race now
        if (!game.isJoin && !game.isOver && allFinished(game)) {
            await endGame(gameId);
        }
    } catch (e) {
        console.log(e);
    }
};

const startGameClock = async (gameId, timers) => {
    let game = await Game.findById(gameId);
    if (!game) {
        gameTimers.delete(gameId);
        return;
    }
    game.startTime = new Date().getTime();
    await game.save();
    let time = GAME_SECONDS;
    const tick = () => {
        if (time >= 0) {
            io.to(gameId).emit("timer", {
                countDown: calculateTime(time),
                msg: "Time Remaining",
            });
            time--;
        } else {
            endGame(gameId);
        }
    };
    tick();
    timers.clock = setInterval(tick, 1000);
};

// ───────────────────────── socket events ─────────────────────────

io.on("connection", (socket) => {
    console.log("Socket is Connected");

    // which game / player this socket belongs to
    let currentGameId = null;
    let currentPlayerId = null;

    socket.on("create-game", async ({ nickname }) => {
        console.log("created game emit request is running");
        try {
            let game = new Game();
            const sentence = await getSentence();
            game.words = sentence;
            game.players.push({
                socketID: socket.id,
                nickname,
                isPartyLeader: true,
            });
            game = await game.save();
            const gameId = game._id.toString();
            currentGameId = gameId;
            currentPlayerId = game.players[0]._id.toString();
            socket.join(gameId);
            io.to(gameId).emit("updateGame", game);
        } catch (err) {
            console.log(err);
        }
    });

    socket.on("join-game", async ({ nickname, gameId }) => {
        console.log("Join Game event is Being Listened");
        try {
            if (!gameId.match(/^[0-9a-fA-F]{24}$/)) {
                socket.emit("notCorrectGame", "Please enter a valid game id");
                return;
            }
            let game = await Game.findById(gameId);
            if (!game) {
                socket.emit("notCorrectGame", "Please enter a valid game id");
                return;
            }
            // FIX: was `game.isJoin != null`, which is always true, so people
            // could join a race that had already started.
            if (game.isJoin && !game.isOver) {
                const id = game._id.toString();
                socket.join(id);
                game.players.push({ nickname, socketID: socket.id });
                game = await game.save();
                currentGameId = id;
                currentPlayerId = game.players[game.players.length - 1]._id.toString();
                io.to(id).emit("updateGame", game);
            } else {
                socket.emit(
                    "notCorrectGame",
                    "The game is in progress , please wait for sometime!!"
                );
            }
        } catch (err) {
            console.log(err);
        }
    });

    socket.on("userInput", async ({ userInput, gameId }) => {
        try {
            let game = await Game.findById(gameId);
            if (!game || game.isJoin || game.isOver) return;
            const player = game.players.find((p) => p.socketID === socket.id);
            if (!player) return; // left / removed
            if (player.currentWordIndex >= game.words.length) return; // already done

            if (game.words[player.currentWordIndex] === userInput.trim()) {
                player.currentWordIndex += 1;
                if (player.currentWordIndex !== game.words.length) {
                    game = await game.save();
                    io.to(gameId).emit("updateGame", game);
                } else {
                    const endTime = new Date().getTime();
                    player.WPM = calculateWPM(endTime, game.startTime, player);
                    game = await game.save();
                    socket.emit("done");
                    io.to(gameId).emit("updateGame", game);
                    // FIX: end the race as soon as everybody has finished
                    if (allFinished(game)) await endGame(gameId);
                }
            }
        } catch (e) {
            console.log(e);
        }
    });

    // countdown + game clock (leader only)
    socket.on("timer", async ({ playerId, gameId }) => {
        try {
            if (gameTimers.has(gameId)) return; // already running (e.g. new leader pressed Start)
            const game = await Game.findById(gameId);
            if (!game || !game.isJoin) return;
            const player = game.players.id(playerId);
            if (!player || !player.isPartyLeader) return;

            let countDown = 5;
            const timers = {};
            gameTimers.set(gameId, timers);
            timers.countdown = setInterval(async () => {
                try {
                    if (countDown >= 0) {
                        io.to(gameId).emit("timer", {
                            countDown,
                            msg: "Game Starting",
                        });
                        countDown--;
                    } else {
                        clearInterval(timers.countdown);
                        // FIX: re-read the game (a player may have left meanwhile)
                        const g = await Game.findById(gameId);
                        if (!g) {
                            gameTimers.delete(gameId);
                            return;
                        }
                        g.isJoin = false;
                        const saved = await g.save();
                        io.to(gameId).emit("updateGame", saved);
                        startGameClock(gameId, timers);
                    }
                } catch (e) {
                    console.log(e);
                }
            }, 1000);
        } catch (e) {
            console.log(e);
        }
    });

    // player pressed "Back to Home" (or closed the game screen)
    socket.on("leave-game", async ({ gameId }) => {
        if (!currentGameId || gameId !== currentGameId) return; // stale / not ours
        const gId = currentGameId;
        const pId = currentPlayerId;
        currentGameId = null;
        currentPlayerId = null;
        socket.leave(gId);
        await removePlayer(gId, pId);
    });

    // connection dropped -> wait a bit for the client to come back
    socket.on("disconnect", () => {
        if (!currentGameId || !currentPlayerId) return;
        const gId = currentGameId;
        const pId = currentPlayerId;
        const t = setTimeout(() => {
            pendingLeaves.delete(pId);
            removePlayer(gId, pId);
        }, RECONNECT_GRACE_MS);
        pendingLeaves.set(pId, t);
    });

    // client reconnected with a new socket id -> reattach it to its player
    socket.on("rejoin-game", async ({ gameId, playerId }) => {
        try {
            const game = await Game.findById(gameId);
            const player = game && game.players.id(playerId);
            if (!player) {
                socket.emit("notCorrectGame", "You were removed from this game");
                return;
            }
            const t = pendingLeaves.get(playerId);
            if (t) {
                clearTimeout(t);
                pendingLeaves.delete(playerId);
            }
            player.socketID = socket.id;
            await game.save();
            currentGameId = gameId;
            currentPlayerId = playerId;
            socket.join(gameId);
            io.to(gameId).emit("updateGame", game);
        } catch (e) {
            console.log(e);
        }
    });
});

mongoose
    .connect(DB)
    .then(() => {
        console.log("MongoDB Connected Successfully...");
    })
    .catch((err) => {
        console.log(err);
    });

server.listen(process.env.PORT, "0.0.0.0", () => {
    console.log(`server Started and running on port ${process.env.PORT}`);
});