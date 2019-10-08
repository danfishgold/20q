function quiz_has_metadata(quiz) {
  return quiz.title && quiz.date && quiz.image
}

function quiz_has_items(quiz) {
  return quiz.items !== undefined && quiz.items !== null
}

module.exports = { quiz_has_metadata, quiz_has_items }
