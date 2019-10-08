const haaretz = require('./haaretz')

async function handler(event, context) {
  const recents = await haaretz.fetch_recent_quizes()
  return { statusCode: 200, body: JSON.stringify(recents) }
}

module.exports = { handler }
