const request = require("request-promise-native");
const moment = require("moment");
const express = require("express");
const cors = require("cors");
const low = require("lowdb");
const FileSync = require("lowdb/adapters/FileSync");

const db = low(new FileSync(".data/db.json"));
db.set("quizes", []).write();

const app = express();
app.use(cors());

app.use(express.static("public"));

const base_url = "https://www.haaretz.co.il";
const recent_quizes_url = "/json/cmlink/7.7698855?vm=whtzResponsive&pidx=0";

/// Fetch the metadata for the recent quizes and returns them.
async function fetch_recent_quizes() {
  const req = await request(base_url + recent_quizes_url);
  const quizes_json = JSON.parse(req);
  const quizes = quizes_json.items
    .map(quiz => {
      return {
        id: quiz.id,
        // sometimes the size of the image is 1x1, so I remove the constraint
        // from the url ("w_1,h_1")
        image: quiz.image.path.replace(/w_\d+,h_\d+,/g, ""),
        date: quiz.publishDate,
        title: quiz.title
      };
    })
    // some of the items in this list are ads or something, so I filter
    // only the articles themselves (ads don't have publisDates)
    .filter(quiz_has_metadata);
  update_database(quizes);
  return quizes;
}

/// Fetch the questions and answers for all quizes in the original database.
async function fetch_quiz_database() {
  // const yoanas_xls_url = "/st/inter/DB/heb/20q/20q.xlsx";
  const db_url = "/st/c/work/guy/2018/21q/data.js";

  const db_req = await request(base_url + db_url);
  const db_text = db_req.replace("\\'", "'").replace("var newData = ", "");
  const db_json = JSON.parse(db_text);
  const db_objects = Object.keys(db_json).map(id => {
    return { id, questions: db_json[id] };
  });
  return db_objects;
}

/// Update the local cache with new quizes.
async function update_database(quizes) {
  for (const quiz of quizes) {
    const record = db.get("quizes").find({ id: quiz.id });
    if (record.value()) {
      record.assign(quiz).write();
    } else {
      db.get("quizes")
        .push(quiz)
        .write();
    }
  }
}

/// Fetch the recent quizes and update the local cache.
async function fetch_and_cache_recent_quizes() {
  const quizes = await fetch_recent_quizes();
  update_database(quizes);
  return quizes;
}

/// Fetch all questions and answers and update the local cache.
async function fetch_and_cache_quiz_database() {
  const quizes = await fetch_quiz_database();
  update_database(quizes);
  return quizes;
}

/// Get a quiz from the local cache.
function get_local_quiz_by_id(id) {
  return db
    .get("quizes")
    .find({ id })
    .value();
}

function local_quiz_exists(id) {
  return get_local_quiz_by_id != undefined;
}

/// Try to get a quiz from the local cache, and if it isn't there,
/// try to fetch it from the server.
async function fetch_and_cache_quiz_by_id(id) {
  const first_chance = get_local_quiz_by_id(id);
  if (!first_chance || !quiz_has_questions(first_chance)) {
    await fetch_and_cache_quiz_database();
  }
  const second_chance = get_local_quiz_by_id(id);
  if (!quiz_has_metadata(second_chance)) {
    await fetch_and_cache_recent_quizes();
  }
  const third_chance = get_local_quiz_by_id(id);
  if (quiz_has_metadata(third_chance)) {
    return third_chance;
  } else {
    return undefined;
  }
}

async function fetch_and_cache_latest_quiz() {
  const recent = await fetch_and_cache_recent_quizes();
  const latest = min_by(
    recent,
    quiz => -moment(quiz.date, "DD.MM.YYYY").unix()
  );
  const quiz = await fetch_and_cache_quiz_by_id(latest.id);
  return quiz;
}

function quiz_has_metadata(quiz) {
  return quiz.title && quiz.date && quiz.image;
}

function quiz_has_questions(quiz) {
  return quiz.questions;
}

app.get("/quizes/latest", function(request, response) {
  fetch_and_cache_latest_quiz()
    .then(quiz => response.send(quiz))
    .catch(err => response.send({ err }));
});

app.get("/quizes/recent", function(request, response) {
  fetch_and_cache_recent_quizes()
    .then(quizes => response.send(quizes))
    .catch(err => response.send({ err }));
});

app.get("/quizes/:quiz_id", function(request, response) {
  const id = request.params.quiz_id;
  fetch_and_cache_quiz_by_id(id)
    .then(quiz => response.send(quiz))
    .catch(err => response.send({ err }));
});

app.get("/", function(request, response) {
  response.sendFile(__dirname + "/views/index.html");
});

const listener = app.listen(process.env.PORT | 5000, function() {
  console.log("Your app is listening on port " + listener.address().port);
});

function min_by(array, key_function) {
  if (array.length == 0) {
    return [];
  }
  var min_val;
  var min_idx;
  for (const idx of range(array.length)) {
    const val = key_function(array[idx]);
    if (!min_val || val < min_val) {
      min_val = val;
      min_idx = idx;
    }
  }
  return array[min_idx];
}

function range(n) {
  return Array.from({ length: n }, (v, k) => k);
}
