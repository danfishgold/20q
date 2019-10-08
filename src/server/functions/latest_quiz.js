const haaretz = require('./haaretz')
const { fetch_quiz } = require('./quiz_by_id')

async function handler(event, context) {
  const recents = await haaretz.fetch_recent_quizes()
  const max_date = Math.max(...recents.map(quiz => quiz.date))
  const latest_quiz = recents.filter(quiz => quiz.date == max_date)[0]
  try {
    const quiz = await fetch_quiz(latest_quiz.id)
    return { statusCode: 200, body: JSON.stringify(quiz) }
  } catch (_) {
    return { statusCode: 500 }
  }
}

module.exports = { handler }
