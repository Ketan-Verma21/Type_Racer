let io = null;

module.exports = {
    setIO: (instance) => {
        io = instance;
    },
    getIO: () => io,
};
