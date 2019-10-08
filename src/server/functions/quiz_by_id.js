const db = require('./db')
const haaretz = require('./haaretz')
const util = require('./util')

async function fetch_quiz(quiz_id) {
  const db_quiz = await db.fetch_quiz(quiz_id)
  if (
    !db_quiz ||
    !util.quiz_has_metadata(db_quiz) ||
    !util.quiz_has_items(db_quiz)
  ) {
    const haaretz_quiz = await haaretz.fetch_quiz(quiz_id)
    await db.create_quiz(haaretz_quiz)
    return haaretz_quiz
  } else {
    return db_quiz
  }
}
async function handler(event, context) {
  try {
    const quiz = await fetch_quiz(event.queryStringParameters.quiz_id)
    return { statusCode: 200, body: JSON.stringify(quiz) }
  } catch (err) {
    return { statusCode: 500, body: err.toString() }
  }
}

module.exports = { fetch_quiz, handler }
