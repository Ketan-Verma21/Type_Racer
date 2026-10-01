// leaving, dropping and coming back
const gameService = require("../services/gameService");
const reconnectService = require("../services/reconnectService");

module.exports = (io, socket, session) => {
    // player pressed "Back to Home" (or closed the game screen)
    socket.on("leave-game", async ({ gameId }) => {
        if (!session.gameId || gameId !== session.gameId) return; // stale / not ours
        const gId = session.gameId;
        const pId = session.playerId;
        session.gameId = null;
        session.playerId = null;
        socket.leave(gId);
        await gameService.removePlayer(gId, pId);
    });

    // connection dropped -> give the client a moment to come back
    socket.on("disconnect", () => {
        if (!session.gameId || !session.playerId) return;
        const gId = session.gameId;
        const pId = session.playerId;
        reconnectService.scheduleRemoval(pId, () => gameService.removePlayer(gId, pId));
    });

    // client reconnected with a new socket id -> reattach it to its player
    socket.on("rejoin-game", async ({ gameId, playerId }) => {
        try {
            const result = await gameService.reattachPlayer(gameId, playerId, socket.id);
            if (!result) {
                socket.emit("notCorrectGame", "You were removed from this game");
                return;
            }
            reconnectService.cancelRemoval(playerId);
            session.gameId = gameId;
            session.playerId = playerId;
            session.nickname = result.player.nickname;
            socket.join(gameId);
            io.to(gameId).emit("updateGame", result.game);
        } catch (e) {
            console.log(e);
        }
    });
};
