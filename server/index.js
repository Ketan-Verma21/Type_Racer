// Entry point: create the servers, connect the database, register socket handlers.
const express = require("express");
const mongoose = require("mongoose");
const http = require("http");
const dotenv = require("dotenv");
dotenv.config();

const { setIO } = require("./utils/io");
const registerSocketHandlers = require("./sockets");

const app = express();
const server = http.createServer(app);
const io = require("socket.io")(server);
app.use(express.json());

setIO(io);
registerSocketHandlers(io);

mongoose
    .connect(process.env.MONGO_URL)
    .then(() => console.log("MongoDB Connected Successfully..."))
    .catch((err) => console.log(err));

server.listen(process.env.PORT, "0.0.0.0", () => {
    console.log(`server Started and running on port ${process.env.PORT}`);
});
