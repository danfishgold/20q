// require('dotenv').config()
// import { query as q, Client } from 'faunadb'

// const client = new Client({ secret: process.env.FAUNADB_SECRET_KEY })

export async function fetch_quiz(quiz_id) {
  // try {
  //   const result = await client.query(
  //     q.Get(q.Match(q.Index('quizes_by_id'), quiz_id)),
  //   )
  //   return result.data
  // } catch {
  //   return {}
  // }
  return {}
}

export async function save_quiz(quiz) {
  // return await client.query(q.Create(q.Collection('quizes'), { data: quiz }))
}
