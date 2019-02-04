module Main exposing (main)

import Array exposing (Array)
import Browser exposing (application)
import Browser.Navigation as Nav
import Css exposing (..)
import Css.Global exposing (..)
import Css.Media as Media exposing (only, screen, withMedia)
import Html.Styled exposing (Html, div, h1, h2, img, p, span, text)
import Html.Styled.Attributes exposing (css, src, style)
import Html.Styled.Events exposing (onClick)
import Http
import Icons
import Json.Decode as Json
import Remote exposing (Remote)
import Time exposing (Posix)
import Url exposing (Url)


type alias Model =
    { quiz : Remote Quiz
    , showErrors : Bool
    , key : Nav.Key
    }


type State
    = LoadingQuizListPage
    | QuizListPageError Http.Error
    | QuizListPage (List (QuizMetadata {}))
    | LoadingQuizPageWithId String
    | LoadingQuizPageWithMetadata (QuizMetadata {})
    | QuizPageError String Http.Error
    | QuizPage Quiz


stateToUrl : State -> String
stateToUrl state =
    case state of
        LoadingQuizListPage ->
            ""

        QuizListPageError _ ->
            ""

        QuizListPage _ ->
            ""

        LoadingQuizPageWithId id ->
            "" ++ id

        LoadingQuizPageWithMetadata { id } ->
            "" ++ id

        QuizPageError id _ ->
            "" ++ id

        QuizPage { id } ->
            "" ++ id


type alias QuizMetadata a =
    { a
        | title : String
        , id : String
        , image : String
        , posix : Posix
    }


type alias Quiz =
    QuizMetadata { questions : Array Question }


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


type Msg
    = HandleGetQuiz (Remote Quiz)
    | SetQuestionStatus Int QuestionStatus
    | ShowErrors
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url


main : Program () Model Msg
main =
    application
        { init = init
        , update = update
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        , subscriptions = subscriptions
        }


finalScore : Quiz -> Maybe ( Float, Int )
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
                ( List.sum values
                , List.length <| List.filter ((==) 0.5) values
                )


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


quizMetadataDecoder : Json.Decoder (QuizMetadata {})
quizMetadataDecoder =
    Json.map4
        (\title image posix id ->
            { title = title
            , image = image
            , posix = posix
            , id = id
            }
        )
        (Json.field "title" Json.string)
        (Json.field "image" Json.string)
        (Json.field "posix" <| Json.map Time.millisToPosix <| Json.int)
        (Json.field "id" Json.string)


quizQuestionsDecoder : QuestionStatus -> Json.Decoder (Array Question)
quizQuestionsDecoder questionStatus =
    Json.field "questions" <| Json.array <| questionDecoder questionStatus


quizDecoder : QuestionStatus -> Json.Decoder Quiz
quizDecoder questionStatus =
    Json.map2
        (\{ id, title, image, posix } questions ->
            { title = title
            , image = image
            , posix = posix
            , id = id
            , questions = questions
            }
        )
        quizMetadataDecoder
        (quizQuestionsDecoder questionStatus)


questionDecoder : QuestionStatus -> Json.Decoder Question
questionDecoder status =
    Json.map2 (\q a -> Question q a status)
        (Json.field "question" Json.string)
        (Json.field "answer" Json.string)


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url key =
    case url.fragment of
        Nothing ->
            quizListInit key

        Just "" ->
            quizListInit key

        Just quizId ->
            quizInit quizId key


quizInit : String -> Nav.Key -> ( Model, Cmd Msg )
quizInit quizId key =
    ( { quiz = Remote.Loading --state = LoadingQuizPageWithId quizId
      , showErrors = False
      , key = key
      }
    , Remote.get "http://localhost:5000/quizes/latest"
        HandleGetQuiz
        (quizDecoder AnswerHidden)
    )


quizListInit : Nav.Key -> ( Model, Cmd Msg )
quizListInit key =
    ( { quiz = Remote.Loading --state = LoadingQuizListPage
      , showErrors = False
      , key = key
      }
    , Remote.get "http://20q.glitch.me/quizes/latest"
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
                    Remote.map (setQuestionStatus index status)
                        model.quiz
              }
            , Cmd.none
            )

        ShowErrors ->
            ( { model | showErrors = True }, Cmd.none )

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( model, Cmd.none )


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


transitionWidth =
    px 700


button isActive =
    Html.Styled.styled Html.Styled.button
        [ padding <| px 10
        , borderRadius <| px 3
        , textDecoration none
        , border <| px 0
        , if isActive then
            Css.backgroundColor <| hex "4590E6"

          else
            Css.backgroundColor <| hex "B3D7FF"
        , color <| hex "FFFFFF"
        , fontSize <| rem 1.2
        , property "-webkit-appearence" "none"
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "20 שאלות"
    , body =
        [ global
            [ everything
                [ fontFamilies [ "Helvetica", "Arial" ]
                ]
            ]
        , Html.Styled.node "main"
            [ css
                [ textAlign right
                , property "direction" "rtl"
                , width <| pct 95
                , maxWidth <| transitionWidth
                , marginLeft <| auto
                , marginRight <| auto
                , fontSize <| rem 1.2
                ]
            ]
            (body model)
        ]
            |> List.map Html.Styled.toUnstyled
    }


body : Model -> List (Html Msg)
body model =
    case model.quiz of
        Remote.Loading ->
            [ h1 [] [ text "20 שאלות, והכותרת היא:" ], text "רק רגע אחד..." ]

        Remote.Failure err ->
            httpErrorBody model.showErrors err

        Remote.Success quiz ->
            quizBody quiz


httpErrorBody : Bool -> Http.Error -> List (Html Msg)
httpErrorBody showErrors err =
    let
        wrapper elements =
            h1 [] [ text "20 שאלות והכותרת היא: שיט, רגע יש שגיאה" ] :: elements
    in
    case err of
        Http.NetworkError ->
            wrapper [ p [] [ text "השרת לא מגיב" ] ]

        Http.BadUrl url ->
            wrapper [ p [] [ text <| "יש בעיה בכתובת הזאת: " ++ url ] ]

        Http.BadStatus code ->
            wrapper [ p [] [ text <| "השרת החזיר את הקוד " ++ String.fromInt code ++ ", מה שזה לא אומר" ] ]

        Http.Timeout ->
            wrapper [ p [] [ text <| "לקח לשרת יותר מדי זמן להגיב" ] ]

        Http.BadBody body_ ->
            if showErrors then
                wrapper
                    [ p [] [ text <| "השרת לא יודע איך להתמודד עם זה:" ]
                    , p [] [ text body_ ]
                    ]

            else
                wrapper
                    [ p [] [ text <| "השרת שלח לי משהו שאני לא יודע איך להתמודד איתו" ]
                    , button True [ onClick ShowErrors ] [ text "זה בסדר, אני דן" ]
                    ]


quizBody : Quiz -> List (Html Msg)
quizBody quiz =
    [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ quiz.title ]
    , img
        [ src quiz.image
        , css
            [ withMedia [ only screen [ Media.maxWidth transitionWidth ] ]
                [ Css.width <| vw 100
                , position relative
                , left <| pct 50
                , right <| pct 50
                , marginLeft <| vw -50
                , marginRight <| vw -50
                ]
            , withMedia [ only screen [ Media.minWidth transitionWidth ] ]
                [ width <| pct 100
                ]
            ]
        ]
        []
    , div
        [ css
            [ property "display" "grid"
            ]
        ]
        (Array.toList quiz.questions
            |> List.indexedMap questionView
        )
    , case finalScore quiz of
        Nothing ->
            text ""

        Just ( score, halfCount ) ->
            h2 []
                [ text <|
                    if halfCount > 0 then
                        "התוצאה הסופית: "
                            ++ String.fromFloat score
                            ++ " תשובות נכונות, כולל "
                            ++ String.fromInt halfCount
                            ++ " חצאי נקודה."

                    else
                        "התוצאה הסופית: "
                            ++ String.fromFloat score
                            ++ " תשובות נכונות."
                ]
    ]


questionView : Int -> Question -> Html Msg
questionView index { question, answer, status } =
    let
        col start end =
            css
                [ property
                    "grid-column"
                    (String.fromInt start ++ " / " ++ String.fromInt end)
                , property "align-self" "start"
                ]

        row attrs children =
            div
                (css
                    [ property "display" "grid"
                    , property "grid-template-columns" "1.5rem 1fr 7rem"
                    , property "grid-column-gap" "1rem"
                    , paddingTop <| px 10
                    , paddingBottom <| px 10
                    ]
                    :: attrs
                )
                children

        questionNumberSpan =
            span [ col 1 2 ] [ text <| String.fromInt (index + 1) ++ "." ]

        questionSpan =
            span [ col 2 3 ] [ text question ]

        showAnswerButton isActive =
            button isActive
                [ col 3 4
                , onClick (SetQuestionStatus index AnswerShown)
                ]
                [ text "תשובה" ]

        answerSpan =
            span
                [ col 2 3, style "background" "#eee", css [ padding <| px 10 ] ]
                [ text answer ]

        answerOptionsRow =
            [ Correct, Half, Incorrect ]
                |> List.map (setScoreSvg (Answered >> SetQuestionStatus index))
                |> div
                    [ col 2 3
                    , css
                        [ paddingTop <| px 15
                        , textAlign center
                        , property "direction" "ltr"
                        ]
                    ]
    in
    case status of
        AnswerHidden ->
            row [] [ questionNumberSpan, questionSpan, showAnswerButton True ]

        AnswerShown ->
            row []
                [ questionNumberSpan
                , questionSpan
                , showAnswerButton False
                , answerSpan
                , answerOptionsRow
                ]

        Answered score ->
            row [ style "background" (backgroundColor score) ]
                [ questionNumberSpan, questionSpan ]


setScoreSvg : (Score -> msg) -> Score -> Html.Styled.Html msg
setScoreSvg toMsg score =
    case score of
        Correct ->
            Icons.v (toMsg score)

        Incorrect ->
            Icons.x (toMsg score)

        Half ->
            Icons.half (toMsg score)


backgroundColor : Score -> String
backgroundColor score =
    case score of
        Correct ->
            "#B8E68A"

        Incorrect ->
            "#FF9999"

        Half ->
            "#FFD966"


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
