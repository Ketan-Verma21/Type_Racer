const express = require("express");
const mongoose = require("mongoose");
const http = require("http");
const dotenv = require("dotenv");
const Game = require("./Models/Game");
const getSentence = require("./api/getSentence");
// Creating a Server
const app = express();
const server = http.createServer(app);
const port = process.env.PORT || 3000;
var io = require('socket.io')(server);

// Middleware
dotenv.config();
app.use(express.json());


//Connecting to MongoDB
const DB = process.env.MONGO_URL;

// Listening to the io events

io.on("connection", (socket) => {
    console.log("Socket is Connected");
    socket.on('create-game', async ({ nickname }) => {
        console.log("created game emit request is running");
        try {

            let game = new Game();
            const sentence = await getSentence();
            game.words = sentence;
            let player = {
                socketID: socket.id,
                nickname,
                isPartyLeader: true,

            };
            game.players.push(player);
            game = await game.save();
            const gameId = game._id.toString();
            socket.join(gameId);
            io.to(gameId).emit('updateGame', game);
        } catch (err) {
            console.log(err);
        }
    });
    socket.on("join-game", async ({ nickname, gameId }) => {
        console.log("Join Game event is Being Listened");
        try {
            if (!gameId.match(/^[0-9a-fA-F]{24}$/)) {
                socket.emit("notCorrectGame", "Please enter a valid game id");
                return;
            }
            let game = await Game.findById(gameId);
            if (game.isJoin != null) {
                const id = game._id.toString();
                let player = {
                    nickname,
                    socketID: socket.id,

                }
                socket.join(id);
                game.players.push(player);
                game = await game.save();
                io.to(gameId).emit('updateGame', game);
            } else {

                socket.emit("notCorrectGame", "The game is in progress , please wait for sometime!!");
            }

        } catch (err) {
            console.log(err);
        }
    });
    socket.on("userInput",async({userInput,gameId})=>{
        let game = await Game.findById(gameId);
        if(!game.isJoin && !game.isOver){
           let player=game.players.find((playerr)=>playerr.socketID===socket.id) ;
           if(game.words[player.currentWordIndex]===userInput.trim()){
                player.currentWordIndex+=1;
                if(player.currentWordIndex!==game.words.length){
                    game=await game.save();
                    io.to(gameId).emit('updateGame',game);
                }else{
                    let endTime = new Date().getTime();
                    let {startTime}=game;
                    player.WPM=calculateWPM(endTime,startTime,player);
                    game=await game.save();
                    socket.emit("done");
                    io.to(gameId).emit("updateGame",game);

                }
           }
        }
    });
    //timer Listener
    socket.on('timer', async ({ playerId, gameId }) => {
        let countDown = 5;
        let game = await Game.findById(gameId);
        let player = game.players.id(playerId);
        if (player.isPartyLeader) {
            let timerId = setInterval(async () => {
                if (countDown >= 0) {
                    io.to(gameId).emit("timer", {
                        countDown,
                        msg: "Game Starting",
                    });
                    console.log(countDown);
                    countDown--;
                } else {
                    game.isJoin=false;
                    clearInterval(timerId);
                    game=await game.save();
                    io.to(gameId).emit("updateGame",game);
                    startGameClock(gameId);

                }

            }, 1000)
        }

    });
});

const startGameClock=async(gameId)=>{
    let game = await Game.findById(gameId);
    game.startTime=new Date().getTime();
    game=await game.save();
    let time =120;
    let timerId =setInterval(( function  gameIntervalFunc (){
        if(time>=0){
            const timeFormat= calculateTime(time);
            io.to(gameId).emit("timer",
            {
                countDown:timeFormat,
                msg:"Time Remaining"
            })
            time--;
        }else{
            (async ()=>{
                try{
                    let endTime = new Date().getTime();
            let game = await Game.findById(gameId);
            let {startTime}=game;
            game.isOver=true;
            game.players.forEach((player,index)=>{
                if(player.WPM==-1){
                    game.players[index].WPM=calculateWPM(endTime,startTime,player);
                }
            })
            
            game=await game.save();
            io.to(gameId).emit("updateGame",game);
            clearInterval(timerId);
                }catch(e){
                    console.log(e);
                }
            }
            )();
            
        };
        return gameIntervalFunc
    })(),1000)
}
const calculateTime=(time)=>{
    let min = Math.floor(time/60);
    let second=time%60;
    return `${min}:${second<10?"0"+second:second}`;

}
const calculateWPM=(endTime,startTime,player)=>{
    const timeTaken =((endTime-startTime)/1000)/60;
     let wordsTyped =player.currentWordIndex;
    const WPM =Math.floor(wordsTyped/timeTaken);
    return WPM;
}
mongoose.connect(DB).then(() => {
    console.log("MongoDB Connected Successfully...");
    //    console.log("Yes");
}).catch((err) => {
    console.log(err);

});

server.listen(process.env.PORT, "0.0.0.0", () => {
    console.log(`server Started and running on port ${process.env.PORT}`);
})