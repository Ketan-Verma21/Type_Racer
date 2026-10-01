const axios = require("axios");
const dotenv = require("dotenv");
dotenv.config();
const getSentence = async () => {
  const res = await axios.get(process.env.API_URL, {
    headers: { 'X-Api-Key': process.env.API_KEY },
  });

  // response is an array: [{ quote, author, ... }]
  const quote = res.data[0].quote;

  // trim + collapse repeated spaces so split() never yields empty words
  return quote.trim().split(/\s+/);
};
module.exports=getSentence;