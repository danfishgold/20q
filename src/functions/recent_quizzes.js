const haaretz = require('./haaretz')

const recent_quizzes = [
  {
    id: '1.8290332',
    image: 'https://img.haarets.co.il/img/1.8290940/4097286255.jpg',
    date: 1576713600,
    title: 'בסרט "ילדות רעות", מה לובשות התלמידות המקובלות בימי רביעי?',
  },
  {
    id: '1.8259555',
    image: 'https://img.haarets.co.il/img/1.8261244/2034613964.jpg',
    date: 1576108800,
    title: 'בסדרה "הנוכלות", מה שם תוכנית הריאליטי שבה משתתפות מירי ותקווה?',
  },
  {
    id: '1.8225104',
    image: 'https://img.haarets.co.il/img/1.8226810/3691626105.gif',
    date: 1575504000,
    title: 'לפי שם שיר של סינדי לאופר, מה עושה כסף?',
  },
  {
    id: '1.8188797',
    image: 'https://img.haarets.co.il/img/1.8195120/2648335371.jpg',
    date: 1574899200,
    title: 'מה שינתה נעמי שמר במילות השיר "הטיול הקטן" (לטיול יצאנו") ומדוע?',
  },
  {
    id: '1.8160133',
    image: 'https://img.haarets.co.il/img/1.8160197/3873833520.jpg',
    date: 1574294400,
    title: "בפסקול של איזה סרט הופיע שיר הבכורה של להקת דסטיניז צ'יילד?",
  },
  {
    id: '1.8127652',
    image: 'https://img.haarets.co.il/img/1.8128489/2803558581.jpg',
    date: 1573689600,
    title: 'מהי המדינה בעלת צפיפות האוכלוסין הגבוהה בעולם?',
  },
  {
    id: '1.8092434',
    image: 'https://img.haarets.co.il/img/1.8093124/1081200362.jpg',
    date: 1573084800,
    title:
      'בספר ובסרט "הסיפור שאינו נגמר", איזו פעולה נדרשת להצלת ממלכת פנטזיה?',
  },
]

async function handler(event, context) {
  const recents = recent_quizzes // await haaretz.fetch_recent_quizzes()
  return { statusCode: 200, body: JSON.stringify(recents) }
}

module.exports = { handler }
