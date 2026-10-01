const mongoose = require("mongoose");

const PlayerSchema = new mongoose.Schema({
    currentWordIndex: { type: Number, default: 0 },
    socketID: { type: String },
    isPartyLeader: { type: Boolean, default: false },
    WPM: { type: Number, default: -1 },
    nickname: { type: String },
    isSpectator: { type: Boolean, default: false }, // joined after the race started
    isEliminated: { type: Boolean, default: false }, // sudden-death
    mistakes: { type: Number, default: 0 },
});

const GameSchema = new mongoose.Schema({
    words: [{ type: String }],
    players: [PlayerSchema],
    isJoin: { type: Boolean, default: true }, // true = lobby
    isOver: { type: Boolean, default: false },
    startTime: { type: Number },
    settings: {
        mode: { type: String, default: "classic" }, // classic | no-mistakes | sudden-death
        timeLimit: { type: Number, default: 120 }, // seconds
        length: { type: String, default: "medium" }, // short | medium | long
        maxPlayers: { type: Number, default: 5 },
    },
});

module.exports = mongoose.model("Game", GameSchema);
