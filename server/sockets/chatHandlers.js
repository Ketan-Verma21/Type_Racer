const chatService = require("../services/chatService");

module.exports = (io, socket, session) => {
    socket.on("chat-message", ({ gameId, text }) => {
        if (gameId !== session.gameId) return;
        const clean = chatService.sanitizeText(text);
        const now = Date.now();
        if (!clean || now - session.lastChatAt < 500) return; // empty or too fast
        session.lastChatAt = now;

        const msg = {
            playerId: session.playerId,
            nickname: session.nickname,
            text: clean,
            ts: now,
        };
        chatService.addMessage(gameId, msg);
        io.to(gameId).emit("chat-message", msg);
    });

    // a client asks for the recent messages (e.g. after joining the game screen)
    socket.on("chat-sync", ({ gameId }) => {
        if (gameId !== session.gameId) return;
        socket.emit("chat-history", chatService.getHistory(gameId));
    });

    socket.on("reaction", ({ gameId, emoji }) => {
        if (gameId !== session.gameId || !chatService.isValidReaction(emoji)) return;
        const now = Date.now();
        if (now - session.lastReactionAt < 200) return;
        session.lastReactionAt = now;
        io.to(gameId).emit("reaction", {
            id: `${now}-${Math.random().toString(36).slice(2, 7)}`,
            nickname: session.nickname,
            emoji,
        });
    });
};
