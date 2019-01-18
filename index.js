const express = require("express");
const cheerio = require("cheerio");
const request = require("request-promise-native");
const cors = require("cors");

const app = express();
app.use(cors());

app.use(express.static("public"));

app.get("/latest_quiz", function(request, response) {
  get_latest_quiz()
    .then(quiz => response.send(quiz))
    .catch(err => response.send(err));
});

async function get_latest_quiz() {
  const base_url = "https://www.haaretz.co.il";
  const all_url = "/magazine/20questions";

  const all_req = await request(base_url + all_url);
  const all_body = cheerio.load(all_req);
  const latest_element = all_body("article.hero");
  const latest_url = latest_element.find("a").attr("href");
  const latest_id = latest_url.match(/magazine\/20questions\/([\d\.]+)/)[1];
  const latest_date = latest_element.find("time").attr("datetime");

  const latest_req = await request(
    base_url + `/magazine/20questions/${latest_id}`
  );
  const latest_body = cheerio.load(latest_req);
  const latest_title = latest_body("main article > header h1").text();
  const latest_image = latest_body("main article > figure img").attr("src");

  const yoanas_xls_url = "/st/inter/DB/heb/20q/20q.xlsx";
  const data_url = "/st/c/work/guy/2018/21q/data.js";

  const data_req = await request(base_url + data_url);
  const data_text = data_req.replace("\\'", "'").replace("var newData = ", "");
  const qna = JSON.parse(data_text)[latest_id];

  return {
    title: latest_title,
    image: latest_image,
    questions: qna.map(qna => {
      return { question: qna["question"], answer: qna["answer"] };
    })
  };
}

// app.get("/", function(request, response) {
//   response.sendFile(__dirname + "/views/index.html");
// });

const listener = app.listen(process.env.PORT, function() {
  console.log("Your app is listening on port " + listener.address().port);
});
