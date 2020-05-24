module Main exposing (main)

import Array
import Browser exposing (application)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Css exposing (..)
import Css.Global exposing (everything, global)
import Css.Media as Media exposing (only, screen, withMedia)
import Date
import Html.Styled exposing (Html, a, div, h1, h2, img, p, span, text)
import Html.Styled.Attributes exposing (alt, css, href, src, style)
import Html.Styled.Events exposing (onClick)
import Http
import Icons
import Page exposing (Page(..), State(..))
import Quiz exposing (Quiz)
import Url exposing (Url)



-- MAIN


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



-- TYPES


type alias Model =
    { pageState : Page.State
    , cachedQuizzes : Maybe (List Quiz.Metadata)
    , showErrors : Bool
    , key : Nav.Key
    }


type Msg
    = HandleGetQuizList (Result Http.Error (List Quiz.Metadata))
    | HandleGetQuiz (Result Http.Error Quiz)
    | SetQuestionStatus Int Quiz.QuestionStatus
    | ShowErrors
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | RequestQuiz Quiz.Id



-- NAVIGATION


initialPageStateAndCommand : Url -> Maybe (List Quiz.Metadata) -> ( Page.State, Cmd Msg )
initialPageStateAndCommand url cachedQuizzes =
    Page.initialStateAndCommand
        url
        cachedQuizzes
        { getLatestQuizzes = Quiz.getLatestQuizzes HandleGetQuizList
        , getQuiz = Quiz.get HandleGetQuiz
        }



-- INIT


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url key =
    let
        ( pageState, cmd ) =
            initialPageStateAndCommand url Nothing
    in
    ( { key = key
      , pageState = pageState
      , showErrors = False
      , cachedQuizzes = Nothing
      }
    , Cmd.batch [ cmd ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleGetQuiz result ->
            let
                newState =
                    case ( model.pageState, result ) of
                        ( Page.QuizPage _, Ok quiz ) ->
                            if quiz.metadata.id == id then
                                QuizPage quiz

                            else
                                model.pageState

                        ( Just id, Err error ) ->
                            QuizPageError id error

                        ( Nothing, _ ) ->
                            model.pageState
            in
            ( { model | pageState = newState }, Cmd.none )

        HandleGetQuizList result ->
            let
                ( newState, newCache ) =
                    if model.pageState == LoadingQuizListPage then
                        case result of
                            Ok quizzes ->
                                ( QuizListPage quizzes, Just quizzes )

                            Err error ->
                                ( QuizListPageError error, Nothing )

                    else
                        ( model.pageState, Nothing )
            in
            ( { model | pageState = newState, cachedQuizzes = newCache }, Cmd.none )

        SetQuestionStatus index status ->
            case model.pageState of
                QuizPage quiz ->
                    ( { model
                        | pageState = QuizPage (Quiz.setQuestionStatus index status quiz)
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
            if Page.fromState model.pageState /= Page.fromUrl url then
                let
                    ( newState, cmd ) =
                        initialPageStateAndCommand url model.cachedQuizzes
                in
                ( { model | pageState = newState }, cmd )

            else
                ( model, Cmd.none )

        RequestQuiz quizId ->
            ( model, Page.push model.key (AQuiz quizId) )



-- VIEW


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
    case model.pageState of
        LoadingQuizListPage ->
            [ h1 [] [ text "20 שאלות" ]
            , text "רק רגע אחד..."
            ]

        QuizListPageError err ->
            h1 [] [ text "שיט, רגע יש שגיאה" ]
                :: httpErrorBody model.showErrors err

        QuizListPage quizzes ->
            quizListBody quizzes

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


transitionWidth =
    px 700


button : Bool -> List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
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


httpErrorBody : Bool -> Http.Error -> List (Html Msg)
httpErrorBody showErrors err =
    case err of
        Http.NetworkError ->
            [ p [] [ text "השרת לא מגיב" ] ]

        Http.BadUrl url ->
            [ p [] [ text <| "יש בעיה בכתובת הזאת: " ++ url ] ]

        Http.BadStatus 500 ->
            [ p []
                [ text <|
                    "הארץ מעצבנים אז אי אפשר לגשת לשאלון הזה. אחרים (בתקווה) כן יעבדו."
                ]
            , a [ href "#" ] [ text "שאר השאלונים" ]
            ]

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


quizListBody : List Quiz.Metadata -> List (Html Msg)
quizListBody quizzes =
    [ h1 [] [ text "20 שאלות" ]
    , div [] (List.map quizMetadataView quizzes)
    ]


quizMetadataView : Quiz.Metadata -> Html Msg
quizMetadataView { title, id, image, date } =
    div
        [ css
            [ boxShadow4 (px 0) (px 3) (px 5) (hex "999")
            , marginTop <| px 30
            , marginBottom <| px 30
            ]
        ]
        [ a
            [ Page.href (AQuiz id)
            , css [ textDecoration none, color <| rgb 0 0 0 ]
            ]
            [ img
                [ src image
                , alt ""
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
                [ h2
                    [ css
                        [ padding <| px 0
                        , marginBottom <| px 10
                        , marginTop <| px 0
                        ]
                    ]
                    [ text title ]
                , Html.Styled.node "date" [] [ text <| Date.toString date ]
                ]
            ]
        ]


quizBody : Quiz -> List (Html Msg)
quizBody quiz =
    [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ quiz.metadata.title ]
    , quizImage quiz.metadata.image
    , div
        [ css
            [ property "display" "grid"
            ]
        ]
        (Array.toList quiz.questions
            |> List.indexedMap questionView
        )
    , case Quiz.finalScore quiz of
        Nothing ->
            text ""

        Just ( score, halfCount ) ->
            h2 []
                [ text <|
                    if halfCount == 0 then
                        "התוצאה הסופית: "
                            ++ String.fromFloat score
                            ++ " תשובות נכונות."

                    else if halfCount == 1 then
                        "התוצאה הסופית: "
                            ++ String.fromFloat score
                            ++ " תשובות נכונות, כולל חצי נקודה אחת."

                    else
                        "התוצאה הסופית: "
                            ++ String.fromFloat score
                            ++ " תשובות נכונות, כולל "
                            ++ String.fromInt halfCount
                            ++ " חצאי נקודה."
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


questionView : Int -> Quiz.Question -> Html Msg
questionView index { question, answer, status } =
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
                , onClick (SetQuestionStatus index Quiz.AnswerShown)
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
                |> List.map (Quiz.setScoreSvg (Quiz.Answered >> SetQuestionStatus index))
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
            row [ style "background" (Quiz.scoreBackgroundColor score) ]
                [ questionNumberSpan, questionSpan, answerSpan ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
