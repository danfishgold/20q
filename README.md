# 20q [NOW DEPRECTATED]

A web client for the Haaretz trivia quizzes.

[Check it out!](https://20q.glitch.me)

## Deprecation

Haaretz changed their website and now I can't crawl it to get the quiz
information. I kept the database and website for posterity and in case this
becomes possible again in the future. Oh well.

## Features

It's very similar to their web client and app version, but it has three major
improvements, two of which are relevant for most people:

1. You can grade half points (for those tricky questions when you know that
   Kiryat Ono has a sister city in the Netherlands, but you're just not sure
   which one.
2. It doesn't hide the answers for questions you've already answered

## Running

If you run `npm run dev` it won't work because you also need the serverless
functions and those functions need some `.env` variables. Instead use
`netlify dev`, which will run `npm run dev` and also run the serverless
functions and also fetch the environment variables from Netlify.

## Deploying

The site is hosted on Netlify. The environment variables are already there and
the `netlify.toml` file tells Netlify how to build the site, which is with
`npm run build`.
