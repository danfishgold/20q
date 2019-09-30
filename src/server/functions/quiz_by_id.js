import * as db from '../db'
import * as haaretz from '../haaretz'
import * as util from '../util'

export async function fetch_quiz(quiz_id) {
  const db_quiz = await db.fetch_quiz(quiz_id)
  if (!util.quiz_has_metadata(db_quiz) || !util.quiz_has_items(db_quiz)) {
    const haaretz_quiz = await haaretz.fetch_quiz(quiz_id)
    await db.save_quiz(haaretz_quiz)
    return haaretz_quiz
  } else {
    return db_quiz
  }
}
export async function handler(event, context) {
  const quiz = await fetch_quiz(event.queryStringParameters.quiz_id)
  return { statusCode: 200, body: JSON.stringify(quiz) }
}
