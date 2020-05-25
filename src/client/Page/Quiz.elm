module Page.Quiz exposing (Model(..), body, init, onResponse, quizId)

import Array
import Css exposing (..)
import Date
import Grid
import Html.Styled exposing (Html, div, h2, img, main_, p, span, styled, text)
import Html.Styled.Attributes exposing (css, src)
import Html.Styled.Events exposing (onClick)
import Http
import Quiz exposing (Quiz)
import SharedView exposing (button, httpErrorBody, onDesktop, onMobile, transitionWidth)


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


body : Bool -> { showErrors : msg, setQuestionStatus : Int -> Quiz.QuestionStatus -> msg } -> Model -> Html msg
body showErrors msgs model =
    main_
        [ css
            [ Grid.display
            , Grid.rowGap <| px 30
            , padding2 (px 60) zero
            ]
        ]
        (content showErrors msgs model)


h1 : List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
h1 attrs =
    Html.Styled.h1 (padded :: attrs)


content : Bool -> { showErrors : msg, setQuestionStatus : Int -> Quiz.QuestionStatus -> msg } -> Model -> List (Html msg)
content showErrors msgs model =
    case model of
        Loading _ ->
            [ h1 [] [ text "20 שאלות, והכותרת היא:" ]
            , p [ padded ] [ text "רק רגע אחד..." ]
            ]

        LoadingWithMetadata { title, image, date } ->
            [ div []
                [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ title ]
                , Html.Styled.node "date"
                    [ padded, css [ display block, marginTop (px -15) ] ]
                    [ text <| Date.toString date ]
                ]
            , quizImage image
            , p [ padded ] [ text "רק רגע אחד..." ]
            ]

        Error _ err ->
            [ h1 [] [ text "20 שאלות והכותרת היא: שיט, רגע יש שגיאה" ]
            , div [ padded ] (httpErrorBody showErrors msgs.showErrors err)
            ]

        Loaded quiz ->
            [ div []
                [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ quiz.metadata.title ]
                , Html.Styled.node "date"
                    [ padded, css [ display block, marginTop (px -15) ] ]
                    [ text <| Date.toString quiz.metadata.date ]
                ]
            , quizImage quiz.metadata.image
            , div []
                (Array.toList quiz.questions
                    |> List.indexedMap (questionView msgs)
                )
            , case Quiz.finalScore quiz of
                Nothing ->
                    text ""

                Just score ->
                    finalScore score
            ]


padded : Html.Styled.Attribute msg
padded =
    css
        [ onMobile [ marginLeft <| px 30, marginRight <| px 30 ] ]


finalScore : Quiz.FinalScore -> Html msg
finalScore { total, halfCount } =
    h2 [ padded ]
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


quizImage : String -> Html msg
quizImage image =
    img
        [ src image
        , css [ width <| pct 100 ]
        ]
        []


questionDiv : List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
questionDiv =
    styled div
        [ Grid.display
        , Grid.templateColumns [ "30px", "1fr", "80px" ]
        , Grid.columnGap <| px 5
        , Grid.rowGap <| px 15
        , alignItems <| flexStart
        , padding2 (px 15) (px 10)
        ]


questionView : { msgs | setQuestionStatus : Int -> Quiz.QuestionStatus -> msg } -> Int -> Quiz.Question -> Html msg
questionView msgs index { question, answer, status } =
    let
        questionNumberSpan =
            span
                [ css [ Grid.column 1 ] ]
                [ text <| String.fromInt (index + 1) ++ "." ]

        questionSpan =
            span [ css [ Grid.column 2 ] ] [ text question ]

        showAnswerButton isActive =
            button isActive
                [ css [ Grid.column 3 ]
                , onClick (msgs.setQuestionStatus index Quiz.AnswerShown)
                ]
                [ text "תשובה" ]

        answerSpan =
            span
                [ css
                    [ Grid.column2 1 -1
                    , padding <| px 10
                    , Css.backgroundColor <| rgba 0 0 0 0.05
                    ]
                ]
                [ text answer ]

        answerOptionsRow =
            [ Quiz.Correct, Quiz.Half, Quiz.Incorrect ]
                |> List.map (Quiz.setScoreSvg (Quiz.Answered >> msgs.setQuestionStatus index))
                |> div
                    [ css
                        [ Grid.column2 1 -1
                        , textAlign center
                        , property "direction" "ltr"
                        ]
                    ]
    in
    case status of
        Quiz.AnswerHidden ->
            questionDiv [] [ questionNumberSpan, questionSpan, showAnswerButton True ]

        Quiz.AnswerShown ->
            questionDiv []
                [ questionNumberSpan
                , questionSpan
                , showAnswerButton False
                , answerSpan
                , answerOptionsRow
                ]

        Quiz.Answered score ->
            questionDiv
                [ css [ backgroundColor <| hex <| Quiz.scoreBackgroundColor score ]
                ]
                [ questionNumberSpan, questionSpan, answerSpan ]
