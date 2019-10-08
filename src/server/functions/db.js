require('dotenv').config()
const Airtable = require('airtable')

Airtable.configure({
  endpointUrl: 'https://api.airtable.com',
  apiKey: process.env.AIRTABLE_API_KEY,
})
const base = Airtable.base('appzwY97blZl4alSE')

async function fetch_quiz(quiz_id) {
  try {
    const results = await base('cached_quizes')
      .select({ filterByFormula: `{id} = ${quiz_id}`, maxRecords: 1 })
      .firstPage()
    const result = results[0]
    if (!result) {
      throw new Error(`No quiz with id ${quiz_id} in the database`)
    }
    return {
      ...result.fields,
      items: JSON.parse(result.fields.items),
    }
  } catch (err) {
    return null
  }
}

async function create_quiz(quiz) {
  await base('cached_quizes').create([
    {
      fields: { ...quiz, items: JSON.stringify(quiz.items) },
    },
  ])
}

module.exports = { fetch_quiz, create_quiz }
