module Quiz exposing
    ( FinalScore
    , Id
    , Metadata
    , Question
    , QuestionStatus(..)
    , Quiz
    , Score(..)
    , finalScore
    , get
    , getLatestQuizzes
    , idFromUrlFragment
    , idUrlFragment
    , scoreBackgroundColor
    , setQuestionStatus
    , setScoreSvg
    )

import Array exposing (Array)
import Date exposing (Date)
import Html.Styled exposing (Html)
import Http
import Icons
import Json.Decode as Json


type alias Quiz =
    { metadata : Metadata
    , questions : Array Question
    }


type alias Metadata =
    { title : String
    , id : Id
    , image : String
    , date : Date
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


type alias FinalScore =
    { total : Float
    , halfCount : Int
    }


type Id
    = Id String


idFromUrlFragment : String -> Id
idFromUrlFragment idString =
    Id idString


idUrlFragment : Id -> String
idUrlFragment (Id id) =
    id


finalScore : Quiz -> Maybe FinalScore
finalScore quiz =
    let
        maybeValues =
            quiz.questions
                |> Array.toList
                |> List.map (.status >> statusToScoreValue)
                |> flatten
    in
    case maybeValues of
        Nothing ->
            Nothing

        Just values ->
            Just
                { total = List.sum values
                , halfCount = List.length <| List.filter ((==) 0.5) values
                }


flatten : List (Maybe a) -> Maybe (List a)
flatten maybes =
    case maybes of
        [] ->
            Just []

        Nothing :: _ ->
            Nothing

        (Just hd) :: tl ->
            case flatten tl of
                Nothing ->
                    Nothing

                Just tl_ ->
                    Just (hd :: tl_)


statusToScoreValue : QuestionStatus -> Maybe Float
statusToScoreValue status =
    case status of
        Answered score ->
            Just (scoreToFloat score)

        _ ->
            Nothing


scoreToFloat : Score -> Float
scoreToFloat score =
    case score of
        Correct ->
            1

        Incorrect ->
            0

        Half ->
            0.5


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


scoreBackgroundColor : Score -> String
scoreBackgroundColor score =
    case score of
        Correct ->
            "#B8E68A"

        Incorrect ->
            "#FF9999"

        Half ->
            "#FFD966"



-- HTTP


get : (Result Http.Error Quiz -> msg) -> Id -> Cmd msg
get toMsg (Id quizId) =
    Http.get
        { url = "/.netlify/functions/quiz_by_id?quiz_id=" ++ quizId
        , expect =
            Http.expectJson toMsg (decoder AnswerHidden)
        }


getLatestQuizzes : (Result Http.Error (List Metadata) -> msg) -> Cmd msg
getLatestQuizzes toMsg =
    Http.get
        { url = "/.netlify/functions/recent_quizzes"
        , expect =
            Http.expectJson toMsg (Json.list metadataDecoder)
        }



-- DECODERS


decoder : QuestionStatus -> Json.Decoder Quiz
decoder questionStatus =
    Json.map2
        (\metadata questions ->
            { metadata = metadata
            , questions = questions
            }
        )
        metadataDecoder
        (Json.field "items" <| Json.array <| questionDecoder questionStatus)


metadataDecoder : Json.Decoder Metadata
metadataDecoder =
    Json.map4
        (\title image date id ->
            { title = title
            , image = image
            , date = date
            , id = Id id
            }
        )
        (Json.field "title" Json.string)
        (Json.field "image" Json.string)
        (Json.field "date" Date.decoder)
        (Json.field "id" Json.string)


questionDecoder : QuestionStatus -> Json.Decoder Question
questionDecoder status =
    Json.map2 (\q a -> Question q a status)
        (Json.field "question" Json.string)
        (Json.field "answer" Json.string)



-- VIEW


setScoreSvg : (Score -> msg) -> Score -> Html msg
setScoreSvg toMsg score =
    case score of
        Correct ->
            Icons.v (toMsg score)

        Incorrect ->
            Icons.x (toMsg score)

        Half ->
            Icons.half (toMsg score)
