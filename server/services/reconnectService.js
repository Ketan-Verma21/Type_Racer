const { RECONNECT_GRACE_MS } = require("../config/constants");

// playerId -> timeout that removes the player if they never come back
const pending = new Map();

// Called when a socket drops. `onExpire` runs if the player doesn't return in time.
const scheduleRemoval = (playerId, onExpire) => {
    cancelRemoval(playerId);
    const timeout = setTimeout(() => {
        pending.delete(playerId);
        onExpire();
    }, RECONNECT_GRACE_MS);
    pending.set(playerId, timeout);
};

// Called when the player reconnects.
const cancelRemoval = (playerId) => {
    const t = pending.get(playerId);
    if (t) {
        clearTimeout(t);
        pending.delete(playerId);
    }
};

module.exports = { scheduleRemoval, cancelRemoval };
