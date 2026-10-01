const Game = require("../Models/Game");
const { getIO } = require("../utils/io");
const { COUNTDOWN_SECONDS } = require("../config/constants");
const { calculateTime } = require("../utils/helpers");

// gameId -> { countdown, clock }  (the intervals running for that game)
const gameTimers = new Map();

const hasTimers = (gameId) => gameTimers.has(gameId);

const clearGameTimers = (gameId) => {
    const t = gameTimers.get(gameId);
    if (t) {
        clearInterval(t.countdown);
        clearInterval(t.clock);
        gameTimers.delete(gameId);
    }
};

// Counts down 5..0, leaves the lobby, then runs the game clock.
// `onTimeUp(gameId)` is called when the clock reaches zero.
const startCountdown = (gameId, onTimeUp) => {
    const io = getIO();
    let countDown = COUNTDOWN_SECONDS;
    const timers = {};
    gameTimers.set(gameId, timers);

    timers.countdown = setInterval(async () => {
        try {
            if (countDown >= 0) {
                io.to(gameId).emit("timer", { countDown, msg: "Game Starting" });
                countDown--;
                return;
            }
            clearInterval(timers.countdown);
            // re-read the game: players may have left during the countdown
            const game = await Game.findById(gameId);
            if (!game) {
                gameTimers.delete(gameId);
                return;
            }
            game.isJoin = false;
            const saved = await game.save();
            io.to(gameId).emit("updateGame", saved);
            await startClock(gameId, timers, onTimeUp);
        } catch (e) {
            console.log(e);
        }
    }, 1000);
};

const startClock = async (gameId, timers, onTimeUp) => {
    const io = getIO();
    const game = await Game.findById(gameId);
    if (!game) {
        gameTimers.delete(gameId);
        return;
    }
    game.startTime = new Date().getTime();
    await game.save();

    let time = game.settings.timeLimit;
    const tick = () => {
        if (time >= 0) {
            io.to(gameId).emit("timer", {
                countDown: calculateTime(time),
                msg: "Time Remaining",
            });
            time--;
        } else {
            onTimeUp(gameId);
        }
    };
    tick();
    timers.clock = setInterval(tick, 1000);
};

module.exports = { hasTimers, clearGameTimers, startCountdown };
