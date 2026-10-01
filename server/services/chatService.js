const { REACTIONS, CHAT_HISTORY_SIZE, CHAT_MAX_LENGTH } = require("../config/constants");

// gameId -> last N messages (in memory only)
const history = new Map();

const addMessage = (gameId, msg) => {
    const arr = history.get(gameId) || [];
    arr.push(msg);
    if (arr.length > CHAT_HISTORY_SIZE) arr.shift();
    history.set(gameId, arr);
};

const getHistory = (gameId) => history.get(gameId) || [];
const clearHistory = (gameId) => history.delete(gameId);

// Returns the cleaned text, or null if the message should be dropped.
const sanitizeText = (text) => {
    if (typeof text !== "string") return null;
    const clean = text.trim().slice(0, CHAT_MAX_LENGTH);
    return clean || null;
};

const isValidReaction = (emoji) => REACTIONS.includes(emoji);

module.exports = { addMessage, getHistory, clearHistory, sanitizeText, isValidReaction };
