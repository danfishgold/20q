const express = require("express");
const cheerio = require("cheerio");
const request = require("request-promise-native");
const app = express();

app.use(express.static("public"));

app.get("/qna", function(request, response) {
  get_latest_questions_and_answers()
    .then(qna => response.send(qna))
    .catch(err => response.send(err));
});

async function get_latest_questions_and_answers() {
  const base_url = "https://www.haaretz.co.il";
  const all_url = "/magazine/20questions";

  const all_req = await request(base_url + all_url);
  const all_body = cheerio.load(all_req);
  const today_element = all_body("article.hero");
  const today_url = today_element.find("a").attr("href");
  const today_id = today_url.match(/magazine\/20questions\/([\d\.]+)/)[1];
  const today_date = today_element.find("time").attr("datetime");

  const today_req = await request(base_url + today_url);
  const today_body = cheerio.load(today_req);
  const today_title = today_body("article.header.h1").text();
  const today_image = today_body("article.figure.img").attr("src");

  const yoanas_xls_url = "/st/inter/DB/heb/20q/20q.xlsx";
  const data_url = "/st/c/work/guy/2018/21q/data.js";

  const data_req = await request(base_url + data_url);
  const data_text = data_req.replace("\\'", "'").replace("var newData = ", "");
  const questions_and_answers = JSON.parse(data_text)[today_id];

  return questions_and_answers;
}

// app.get("/", function(request, response) {
//   response.sendFile(__dirname + "/views/index.html");
// });

const listener = app.listen(process.env.PORT, function() {
  console.log("Your app is listening on port " + listener.address().port);
});
