// Socket events that drive the race. Handlers only parse the event, call a
// service and emit the result - no game rules here.
const gameService = require("../services/gameService");
const timerService = require("../services/timerService");
const Game = require("../Models/Game");
const { cleanName } = require("../utils/helpers");

module.exports = (io, socket, session) => {
    socket.on("create-game", async ({ nickname }) => {
        try {
            nickname = cleanName(nickname);
            if (!nickname) return;
            const { game, player } = await gameService.createGame(socket.id, nickname);
            const gameId = game._id.toString();
            session.gameId = gameId;
            session.playerId = player._id.toString();
            session.nickname = nickname;
            socket.join(gameId);
            io.to(gameId).emit("updateGame", game);
        } catch (err) {
            console.log(err);
        }
    });

    socket.on("join-game", async ({ nickname, gameId }) => {
        try {
            nickname = cleanName(nickname);
            if (!nickname || typeof gameId !== "string" || !gameId.match(/^[0-9a-fA-F]{24}$/)) {
                socket.emit("notCorrectGame", "Please enter a valid game id");
                return;
            }
            const result = await gameService.joinGame(gameId, socket.id, nickname);
            if (result.error) {
                socket.emit("notCorrectGame", result.error);
                return;
            }
            const id = result.game._id.toString();
            session.gameId = id;
            session.playerId = result.player._id.toString();
            session.nickname = nickname;
            socket.join(id);
            io.to(id).emit("updateGame", result.game);
        } catch (err) {
            console.log(err);
        }
    });

    socket.on("update-settings", async ({ gameId, settings }) => {
        try {
            if (gameId !== session.gameId || !settings || timerService.hasTimers(gameId)) return;
            const game = await gameService.applySettings(gameId, session.playerId, settings);
            if (game) io.to(gameId).emit("updateGame", game);
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("timer", async ({ playerId, gameId }) => {
        try {
            if (timerService.hasTimers(gameId)) return; // already running
            const game = await Game.findById(gameId);
            if (!game || !game.isJoin) return;
            const player = game.players.id(playerId);
            if (!player || !player.isPartyLeader) return;
            timerService.startCountdown(gameId, gameService.endGame);
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("userInput", async ({ userInput, gameId }) => {
        try {
            if (typeof userInput !== "string" || !userInput.trim()) return;
            const result = await gameService.processWord(gameId, socket.id, userInput);
            if (!result) return;
            if (result.finished) socket.emit("done");
            io.to(gameId).emit("updateGame", result.game);
            if (gameService.shouldEnd(result.game)) await gameService.endGame(gameId);
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("rematch", async ({ gameId }) => {
        try {
            if (gameId !== session.gameId) return;
            const game = await gameService.rematch(gameId, session.playerId);
            if (!game) return;
            io.to(gameId).emit("updateGame", game);
            io.to(gameId).emit("timer", { countDown: "", msg: "Waiting for players" });
        } catch (e) {
            console.log(e);
        }
    });
};
