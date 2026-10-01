module.exports = {
    RECONNECT_GRACE_MS: 15000, // wait this long for a dropped player to come back
    COUNTDOWN_SECONDS: 5, // "Game Starting" countdown
    MODES: ["classic", "no-mistakes", "sudden-death"],
    TIME_LIMITS: [30, 60, 90, 120], // seconds
    LENGTH_WORDS: { short: 12, medium: 25, long: 45 }, // minimum words per quote length
    REACTIONS: ["😂", "🔥", "👏", "😮", "💀", "❤️"],
    MAX_PLAYERS_LIMIT: 8,
    CHAT_HISTORY_SIZE: 30,
    CHAT_MAX_LENGTH: 140,
};
