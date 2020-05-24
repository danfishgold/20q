module Page.Quiz exposing (Model(..), body, init, onResponse, quizId)

-- import Date

import Array exposing (Array)
import Css exposing (..)
import Html.Styled exposing (Html, div, h1, h2, span, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Http
import Quiz exposing (Quiz)
import SharedView exposing (button, httpErrorBody, quizImage)


type Model
    = Loading Quiz.Id
    | LoadingWithMetadata Quiz.Metadata
    | Error Quiz.Id Http.Error
    | Loaded Quiz



-- INIT


init : { handleGetQuiz : Result Http.Error Quiz -> msg } -> Maybe (List Quiz.Metadata) -> Quiz.Id -> ( Model, Cmd msg )
init msgs cachedQuizzes quizId_ =
    ( case cachedQuizzes of
        Just quizzes ->
            quizzes
                |> List.filter (\{ id } -> id == quizId_)
                |> List.head
                |> Maybe.map LoadingWithMetadata
                |> Maybe.withDefault (Loading quizId_)

        _ ->
            Loading quizId_
    , Quiz.get msgs.handleGetQuiz quizId_
    )



-- HELPERS


quizId : Model -> Quiz.Id
quizId model =
    case model of
        Loading id ->
            id

        LoadingWithMetadata { id } ->
            id

        Error id _ ->
            id

        Loaded { metadata } ->
            metadata.id


onResponse : Result Http.Error Quiz -> Model -> Model
onResponse response model =
    let
        id =
            quizId model
    in
    case response of
        Ok quiz ->
            if quiz.metadata.id == id then
                Loaded quiz

            else
                model

        Err error ->
            Error id error



-- VIEW


body : Bool -> { showErrors : msg, setQuestionStatus : Int -> Quiz.QuestionStatus -> msg } -> Model -> List (Html msg)
body showErrors msgs model =
    case model of
        Loading _ ->
            [ h1 [] [ text "20 שאלות, והכותרת היא:" ]
            , text "רק רגע אחד..."
            ]

        LoadingWithMetadata { title, image } ->
            [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ title ]
            , quizImage image
            , text "רק רגע אחד..."
            ]

        Error _ err ->
            h1 [] [ text "20 שאלות והכותרת היא: שיט, רגע יש שגיאה" ]
                :: httpErrorBody showErrors msgs.showErrors err

        Loaded quiz ->
            [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ quiz.metadata.title ]
            , quizImage quiz.metadata.image
            , div
                [ css
                    [ property "display" "grid"
                    ]
                ]
                (Array.toList quiz.questions
                    |> List.indexedMap (questionView msgs)
                )
            , case Quiz.finalScore quiz of
                Nothing ->
                    text ""

                Just score ->
                    finalScore score
            ]


finalScore : Quiz.FinalScore -> Html msg
finalScore { total, halfCount } =
    h2 []
        [ text <|
            if halfCount == 0 then
                "התוצאה הסופית: "
                    ++ String.fromFloat total
                    ++ " תשובות נכונות."

            else if halfCount == 1 then
                "התוצאה הסופית: "
                    ++ String.fromFloat total
                    ++ " תשובות נכונות, כולל חצי נקודה אחת."

            else
                "התוצאה הסופית: "
                    ++ String.fromFloat total
                    ++ " תשובות נכונות, כולל "
                    ++ String.fromInt halfCount
                    ++ " חצאי נקודה."
        ]


questionView : { msgs | setQuestionStatus : Int -> Quiz.QuestionStatus -> msg } -> Int -> Quiz.Question -> Html msg
questionView msgs index { question, answer, status } =
    let
        col column =
            css
                [ property
                    "grid-column"
                    (String.fromInt column)
                , property "align-self" "start"
                ]

        row attrs children =
            div
                (css
                    [ property "display" "grid"
                    , property "grid-template-columns" "1.5rem 1fr 6rem"
                    , property "grid-column-gap" "1rem"
                    , paddingTop <| px 10
                    , paddingBottom <| px 10
                    ]
                    :: attrs
                )
                children

        questionNumberSpan =
            span [ col 1 ] [ text <| String.fromInt (index + 1) ++ "." ]

        questionSpan =
            span [ col 2 ] [ text question ]

        showAnswerButton isActive =
            button isActive
                [ col 3
                , onClick (msgs.setQuestionStatus index Quiz.AnswerShown)
                ]
                [ text "תשובה" ]

        answerSpan =
            span
                [ col 2
                , css
                    [ padding <| px 10
                    , Css.backgroundColor <| rgba 0 0 0 0.05
                    ]
                ]
                [ text answer ]

        answerOptionsRow =
            [ Quiz.Correct, Quiz.Half, Quiz.Incorrect ]
                |> List.map (Quiz.setScoreSvg (Quiz.Answered >> msgs.setQuestionStatus index))
                |> div
                    [ col 2
                    , css
                        [ paddingTop <| px 15
                        , textAlign center
                        , property "direction" "ltr"
                        ]
                    ]
    in
    case status of
        Quiz.AnswerHidden ->
            row [] [ questionNumberSpan, questionSpan, showAnswerButton True ]

        Quiz.AnswerShown ->
            row []
                [ questionNumberSpan
                , questionSpan
                , showAnswerButton False
                , answerSpan
                , answerOptionsRow
                ]

        Quiz.Answered score ->
            row
                [ css [ backgroundColor <| hex <| Quiz.scoreBackgroundColor score ]
                ]
                [ questionNumberSpan, questionSpan, answerSpan ]
