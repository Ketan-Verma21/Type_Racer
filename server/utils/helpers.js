const calculateTime = (time) => {
    const min = Math.floor(time / 60);
    const second = time % 60;
    return `${min}:${second < 10 ? "0" + second : second}`;
};

// words per minute for a player so far
const calculateWPM = (endTime, startTime, player) => {
    const timeTaken = (endTime - startTime) / 1000 / 60;
    const WPM = Math.floor(player.currentWordIndex / timeTaken);
    return Number.isFinite(WPM) ? WPM : 0;
};

const cleanName = (name) => String(name || "").trim().slice(0, 16);

module.exports = { calculateTime, calculateWPM, cleanName };
