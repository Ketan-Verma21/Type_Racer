const registerGameHandlers = require("./gameHandlers");
const registerChatHandlers = require("./chatHandlers");
const registerConnectionHandlers = require("./connectionHandlers");

// Wires every socket event for each new connection.
module.exports = (io) => {
    io.on("connection", (socket) => {
        console.log("Socket is Connected");

        // per-connection state shared by all handler files
        const session = {
            gameId: null,
            playerId: null,
            nickname: "",
            lastChatAt: 0,
            lastReactionAt: 0,
        };

        registerGameHandlers(io, socket, session);
        registerChatHandlers(io, socket, session);
        registerConnectionHandlers(io, socket, session);
    });
};
