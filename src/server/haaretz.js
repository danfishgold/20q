import fetch from 'node-fetch'
import * as json5 from 'json5'
import * as moment from 'moment'
import { quiz_has_metadata } from './util'

export async function fetch_quiz(quiz_id) {
  const req = await fetch(
    `https://www.haaretz.co.il/magazine/20questions/${quiz_id}`,
  )
  const body = await req.text()
  const idx1 = body.search(/inter20qObj.share = {/)
  const idx2 = body.search(/inter20qObj.data = \[/)
  const share = json5.parse(body.slice(idx1 + 20, idx2))
  const rest = body.slice(idx2)
  const items = json5
    .parse(rest.slice(19, rest.search('</script>')))
    .map(item => {
      return {
        question: item.question.replace(/&quot;/g, '"'),
        answer: item.answer.replace(/&quot;/g, '"'),
      }
    })

  const date = body.match(
    /<meta property="article:published" itemprop="datePublished" content="(\d{4}-\d{2}-\d{2})/,
  )[1]

  const title = body
    .match(/var articlePage\s*=\s*{.*?"name"\s*:\s*"(.*?[^\\])"/s)[1]
    .replace(/\\"/g, '"')
  const id = share.link.match(
    /https:\/\/www.haaretz.co.il\/magazine\/20questions\/([\d\.]+)/,
  )[1]
  const image = fix_image_url(share.img)

  return {
    items,
    title,
    id,
    image,
    date: moment(date, 'YYYY-MM-DD').unix(),
  }
}

export async function fetch_recent_quizes() {
  const req = await fetch(
    'https://www.haaretz.co.il/json/cmlink/7.7698855?vm=whtzResponsive&pidx=0',
  )
  const quizes_json = await req.json()
  return (
    quizes_json.items
      .map(quiz => {
        return {
          id: quiz.id,

          image: fix_image_url(quiz.image.path),
          date: moment(quiz.publishDate, 'DD.MM.YYYY').unix(),
          title: quiz.title,
        }
      })
      // some of the items in this list are ads or something, so I filter
      // only the articles (ads don't have publisDates)
      .filter(quiz_has_metadata)
  )
}

function fix_image_url(image_url) {
  // sometimes the size of the image is 1x1, so I remove the constraint
  // from the url ("w_1,h_1")
  return image_url.replace(/w_\d+,h_\d+,/g, '')
}
