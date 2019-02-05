module Main exposing (main)

import Array exposing (Array)
import Browser exposing (application)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Css exposing (..)
import Css.Global exposing (..)
import Css.Media as Media exposing (only, screen, withMedia)
import Html.Styled exposing (Html, div, h1, h2, img, p, span, text)
import Html.Styled.Attributes exposing (css, href, src, style)
import Html.Styled.Events exposing (onClick)
import Http
import Icons
import Json.Decode as Json
import Task
import Url exposing (Url)


get : String -> (Result Http.Error a -> msg) -> Json.Decoder a -> Cmd msg
get url toMsg decoder =
    Http.get
        { url = url
        , expect = Http.expectJson toMsg decoder
        }


scrollToTop =
    Task.perform (\_ -> NoOp) (Dom.setViewport 0 0)


type alias Model =
    { state : State
    , cachedQuizes : Maybe (List (QuizMetadata {}))
    , showErrors : Bool
    , key : Nav.Key
    }


type Page
    = QuizList
    | AQuiz String


type State
    = LoadingQuizListPage
    | QuizListPageError Http.Error
    | QuizListPage (List (QuizMetadata {}))
    | LoadingQuizPageWithId String
    | LoadingQuizPageWithMetadata (QuizMetadata {})
    | QuizPageError String Http.Error
    | QuizPage Quiz


stateToPage : State -> Page
stateToPage state =
    case state of
        LoadingQuizListPage ->
            QuizList

        QuizListPageError _ ->
            QuizList

        QuizListPage _ ->
            QuizList

        LoadingQuizPageWithId id ->
            AQuiz id

        LoadingQuizPageWithMetadata { id } ->
            AQuiz id

        QuizPageError id _ ->
            AQuiz id

        QuizPage { id } ->
            AQuiz id


urlToPage : Url -> Page
urlToPage url =
    case url.fragment of
        Nothing ->
            QuizList

        Just "" ->
            QuizList

        Just quizId ->
            AQuiz quizId


pageToUrl : Page -> String
pageToUrl page =
    case page of
        QuizList ->
            "/"

        AQuiz quizId ->
            "/#" ++ quizId


pageToStateAndCommand : Page -> Maybe (List (QuizMetadata {})) -> ( State, Cmd Msg )
pageToStateAndCommand page cachedQuizes =
    case page of
        QuizList ->
            case cachedQuizes of
                Nothing ->
                    ( LoadingQuizListPage
                    , get "/quizes/recent"
                        HandleGetQuizList
                        (Json.list quizMetadataDecoder)
                    )

                Just quizes ->
                    ( QuizListPage quizes, Cmd.none )

        AQuiz quizId ->
            ( case cachedQuizes of
                Just quizes ->
                    quizes
                        |> List.filter (\{ id } -> id == quizId)
                        |> List.head
                        |> Maybe.map LoadingQuizPageWithMetadata
                        |> Maybe.withDefault (LoadingQuizPageWithId quizId)

                _ ->
                    LoadingQuizPageWithId quizId
            , get ("/quizes/" ++ quizId)
                HandleGetQuiz
                (quizDecoder AnswerHidden)
            )


type alias QuizMetadata a =
    { a
        | title : String
        , id : String
        , image : String
        , date : String
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
    = HandleGetQuizList (Result Http.Error (List (QuizMetadata {})))
    | HandleGetQuiz (Result Http.Error Quiz)
    | SetQuestionStatus Int QuestionStatus
    | ShowErrors
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | RequestQuiz String
    | NoOp


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
        (\title image date id ->
            { title = title
            , image = image
            , date = date
            , id = id
            }
        )
        (Json.field "title" Json.string)
        (Json.field "image" Json.string)
        (Json.field "date" Json.string)
        (Json.field "id" Json.string)


quizQuestionsDecoder : QuestionStatus -> Json.Decoder (Array Question)
quizQuestionsDecoder questionStatus =
    Json.field "questions" <| Json.array <| questionDecoder questionStatus


quizDecoder : QuestionStatus -> Json.Decoder Quiz
quizDecoder questionStatus =
    Json.map2
        (\{ id, title, image, date } questions ->
            { title = title
            , image = image
            , date = date
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
    let
        ( state, cmd ) =
            pageToStateAndCommand (urlToPage url) Nothing
    in
    ( { key = key
      , state = state
      , showErrors = False
      , cachedQuizes = Nothing
      }
    , cmd
    )


loadingQuizId : State -> Maybe String
loadingQuizId state =
    case state of
        LoadingQuizPageWithId id ->
            Just id

        LoadingQuizPageWithMetadata { id } ->
            Just id

        _ ->
            Nothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleGetQuiz result ->
            let
                newState =
                    case ( loadingQuizId model.state, result ) of
                        ( Just id, Ok quiz ) ->
                            if quiz.id == id then
                                QuizPage quiz

                            else
                                model.state

                        ( Just id, Err error ) ->
                            QuizPageError id error

                        ( Nothing, _ ) ->
                            model.state
            in
            ( { model | state = newState }, Cmd.none )

        HandleGetQuizList result ->
            let
                ( newState, newCache ) =
                    if model.state == LoadingQuizListPage then
                        case result of
                            Ok quizes ->
                                ( QuizListPage quizes, Just quizes )

                            Err error ->
                                ( QuizListPageError error, Nothing )

                    else
                        ( model.state, Nothing )
            in
            ( { model | state = newState, cachedQuizes = newCache }, Cmd.none )

        SetQuestionStatus index status ->
            case model.state of
                QuizPage quiz ->
                    ( { model
                        | state = QuizPage (setQuestionStatus index status quiz)
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ShowErrors ->
            ( { model | showErrors = True }, Cmd.none )

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            if stateToPage model.state /= urlToPage url then
                let
                    ( newState, cmd ) =
                        pageToStateAndCommand (urlToPage url) model.cachedQuizes
                in
                ( { model | state = newState }, cmd )

            else
                ( model, Cmd.none )

        RequestQuiz quizId ->
            ( model, Nav.pushUrl model.key (pageToUrl (AQuiz quizId)) )

        NoOp ->
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
    case model.state of
        LoadingQuizListPage ->
            [ h1 [] [ text "20 שאלות" ]
            , text "רק רגע אחד..."
            ]

        QuizListPageError err ->
            h1 [] [ text "שיט, רגע יש שגיאה" ]
                :: httpErrorBody model.showErrors err

        QuizListPage quizes ->
            quizListBody quizes

        LoadingQuizPageWithId _ ->
            [ h1 [] [ text "20 שאלות, והכותרת היא:" ]
            , text "רק רגע אחד..."
            ]

        LoadingQuizPageWithMetadata { title, image } ->
            [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ title ]
            , quizImage image
            , text "רק רגע אחד..."
            ]

        QuizPageError _ err ->
            h1 [] [ text "20 שאלות והכותרת היא: שיט, רגע יש שגיאה" ]
                :: httpErrorBody model.showErrors err

        QuizPage quiz ->
            quizBody quiz


httpErrorBody : Bool -> Http.Error -> List (Html Msg)
httpErrorBody showErrors err =
    case err of
        Http.NetworkError ->
            [ p [] [ text "השרת לא מגיב" ] ]

        Http.BadUrl url ->
            [ p [] [ text <| "יש בעיה בכתובת הזאת: " ++ url ] ]

        Http.BadStatus code ->
            [ p []
                [ text <|
                    "השרת החזיר את הקוד "
                        ++ String.fromInt code
                        ++ ", מה שזה לא אומר"
                ]
            ]

        Http.Timeout ->
            [ p [] [ text <| "לקח לשרת יותר מדי זמן להגיב" ] ]

        Http.BadBody body_ ->
            if showErrors then
                [ p [] [ text <| "השרת לא יודע איך להתמודד עם זה:" ]
                , p [] [ text body_ ]
                ]

            else
                [ p [] [ text "השרת שלח לי משהו שאני לא יודע איך להתמודד איתו" ]
                , button True [ onClick ShowErrors ] [ text "זה בסדר, אני דן" ]
                ]


quizListBody : List (QuizMetadata {}) -> List (Html Msg)
quizListBody quizes =
    [ h1 [] [ text "20 שאלות" ]
    , quizes
        |> List.map quizMetadataView
        |> div []
    ]


quizMetadataView : QuizMetadata {} -> Html Msg
quizMetadataView { title, id, image, date } =
    div
        [ css
            [ boxShadow4 (px 0) (px 3) (px 5) (hex "999")
            , marginTop <| px 30
            , marginBottom <| px 30
            ]
        ]
        [ Html.Styled.a
            [ href <| pageToUrl (AQuiz id)
            , css [ textDecoration none, color <| rgb 0 0 0 ]
            ]
            [ img
                [ src image
                , css
                    [ width <| pct 100
                    , padding <| px 0
                    , margin <| px 0
                    ]
                ]
                []
            , div
                [ css
                    [ padding <| px 10
                    , margin <| px 0
                    ]
                ]
                [ h2 [ css [ padding <| px 0, marginBottom <| px 10, marginTop <| px 0 ] ] [ text title ]
                , Html.Styled.node "date" [] [ text date ]
                ]
            ]
        ]


quizBody : Quiz -> List (Html Msg)
quizBody quiz =
    [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ quiz.title ]
    , quizImage quiz.image
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


quizImage : String -> Html Msg
quizImage image =
    img
        [ src image
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
                    , property "grid-template-columns" "1.5rem 1fr 6rem"
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
                [ col 2 3
                , css
                    [ padding <| px 10
                    , Css.backgroundColor <| rgba 0 0 0 0.05
                    ]
                ]
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
                [ questionNumberSpan, questionSpan, answerSpan ]


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
