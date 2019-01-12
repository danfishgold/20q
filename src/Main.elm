module Main exposing (main)

import Array exposing (Array)
import Browser exposing (document)
import Html exposing (Html, button, div, h1, img, span, text)
import Html.Attributes exposing (src, style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json


type alias Model =
    { quiz : Remote Quiz }


type alias Quiz =
    { title : String
    , image : Maybe String
    , questions : Array Question
    }


type alias Question =
    { question : String
    , answer : String
    , status : QuestionStatus
    }


type QuestionStatus
    = AnswerHidden
    | AnswerShown
    | Answered Score


type Score
    = Correct
    | Incorrect
    | Half


type Remote data
    = Loading
    | Success data
    | Failure Http.Error


remoteMap : (a -> b) -> Remote a -> Remote b
remoteMap fn remote =
    case remote of
        Loading ->
            Loading

        Success a ->
            Success (fn a)

        Failure err ->
            Failure err


remoteGet : String -> (Remote data -> msg) -> Json.Decoder data -> Cmd msg
remoteGet url toMsg decoder =
    Http.get
        { url = url
        , expect = Http.expectJson (toMsg << remoteFromResult) decoder
        }


remoteFromResult : Result Http.Error data -> Remote data
remoteFromResult result =
    case result of
        Err error ->
            Failure error

        Ok data ->
            Success data


type Msg
    = HandleGetQuiz (Remote Quiz)
    | SetQuestionStatus Int QuestionStatus


main : Program () Model Msg
main =
    document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


quizDecoder : QuestionStatus -> Json.Decoder Quiz
quizDecoder questionStatus =
    Json.map3 Quiz
        (Json.field "title" Json.string)
        (Json.field "image" Json.string |> Json.maybe)
        (Json.field "questions" <| Json.array <| questionDecoder questionStatus)


questionDecoder : QuestionStatus -> Json.Decoder Question
questionDecoder status =
    Json.map2 (\q a -> Question q a status)
        (Json.field "question" Json.string)
        (Json.field "answer" Json.string)


init : () -> ( Model, Cmd Msg )
init () =
    ( { quiz = Loading }
    , remoteGet "https://20q.glitch.me/latest_quiz"
        HandleGetQuiz
        (quizDecoder AnswerHidden)
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleGetQuiz quiz ->
            ( { model | quiz = quiz }, Cmd.none )

        SetQuestionStatus index status ->
            ( { model
                | quiz =
                    remoteMap (setQuestionStatus index status)
                        model.quiz
              }
            , Cmd.none
            )


setQuestionStatus : Int -> QuestionStatus -> Quiz -> Quiz
setQuestionStatus index newStatus quiz =
    case Array.get index quiz.questions of
        Nothing ->
            quiz

        Just question ->
            let
                newQuestion =
                    { question | status = newStatus }

                newQuestions =
                    Array.set index newQuestion quiz.questions
            in
            { quiz | questions = newQuestions }


view : Model -> Browser.Document Msg
view model =
    { title = "20 שאלות"
    , body =
        case model.quiz of
            Loading ->
                [ text "loading" ]

            Success quiz ->
                quizBody quiz

            Failure err ->
                [ text "failure!", text <| Debug.toString err ]
    }


quizBody : Quiz -> List (Html Msg)
quizBody quiz =
    [ div [ style "direction" "rtl" ]
        [ h1 [] [ text quiz.title ]
        , case quiz.image of
            Just image ->
                img [ src image ] []

            Nothing ->
                text ""
        , div []
            (Array.toList quiz.questions
                |> List.indexedMap questionView
                |> List.map (div [])
            )
        ]
    ]


questionView : Int -> Question -> List (Html Msg)
questionView index { question, answer, status } =
    case status of
        AnswerHidden ->
            [ text <| String.fromInt (index + 1) ++ ". " ++ question
            , button
                [ onClick (SetQuestionStatus index AnswerShown) ]
                [ text "הצג תשובה" ]
            ]

        AnswerShown ->
            [ text <| String.fromInt (index + 1) ++ ". " ++ question
            , text answer
            , div []
                [ button
                    [ onClick (SetQuestionStatus index (Answered Correct)) ]
                    [ text "נכון" ]
                , button
                    [ onClick (SetQuestionStatus index (Answered Incorrect)) ]
                    [ text "לא נכון" ]
                , button
                    [ onClick (SetQuestionStatus index (Answered Half)) ]
                    [ text "חצי נקודה" ]
                ]
            ]

        Answered score ->
            [ span
                [ style "background" (backgroundColor score) ]
                [ text <| String.fromInt (index + 1) ++ ". " ++ question ]
            ]


backgroundColor score =
    case score of
        Correct ->
            "lightgreen"

        Incorrect ->
            "pink"

        Half ->
            "yellow"


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
