const axios = require("axios");
const dotenv = require("dotenv");
dotenv.config();
const getSentence = async ()=>{

    const jokeData=await axios.get(process.env.API_URL);
    return jokeData.data.content.split(' ');
}
module.exports=getSentence;