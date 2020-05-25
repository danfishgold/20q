module Main exposing (main)

import Browser exposing (application)
import Browser.Navigation as Nav
import Css exposing (..)
import Css.Global exposing (global)
import Html.Styled exposing (Html)
import Html.Styled.Attributes exposing (css)
import Http
import Page.Quiz as Quiz
import Page.QuizList as QuizList
import Path exposing (Path(..))
import Quiz as Q exposing (Quiz)
import SharedView exposing (fontSize, transitionWidth)
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
    { page : Page
    , cachedQuizzes : Maybe (List Q.Metadata)
    , showErrors : Bool
    , key : Nav.Key
    }


type Page
    = QuizListPage QuizList.Model
    | QuizPage Quiz.Model


type Msg
    = HandleGetQuizList (Result Http.Error (List Q.Metadata))
    | HandleGetQuiz (Result Http.Error Quiz)
    | SetQuestionStatus Int Q.QuestionStatus
    | ShowErrors
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url



-- NAVIGATION


pageToPath : Page -> Path
pageToPath page =
    case page of
        QuizListPage _ ->
            RecentQuizzes

        QuizPage quizPage ->
            AQuiz (Quiz.quizId quizPage)



-- INIT


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url key =
    let
        ( page, cmd ) =
            initPage url Nothing
    in
    ( { key = key
      , page = page
      , showErrors = False
      , cachedQuizzes = Nothing
      }
    , Cmd.batch [ cmd ]
    )


initPage : Url -> Maybe (List Q.Metadata) -> ( Page, Cmd Msg )
initPage url cachedQuizzes =
    case Path.fromUrl url of
        RecentQuizzes ->
            QuizList.init { handleGetQuizList = HandleGetQuizList } cachedQuizzes
                |> Tuple.mapFirst QuizListPage

        AQuiz quizId ->
            Quiz.init { handleGetQuiz = HandleGetQuiz } cachedQuizzes quizId
                |> Tuple.mapFirst QuizPage



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleGetQuiz result ->
            ( { model
                | page =
                    case model.page of
                        QuizPage quizPage ->
                            QuizPage <| Quiz.onResponse result quizPage

                        QuizListPage _ ->
                            model.page
              }
            , Cmd.none
            )

        HandleGetQuizList result ->
            case model.page of
                QuizPage _ ->
                    ( model, Cmd.none )

                QuizListPage _ ->
                    let
                        newSubModel =
                            QuizList.onResponse result
                    in
                    ( { model
                        | page = QuizListPage newSubModel
                        , cachedQuizzes = QuizList.quizzes newSubModel
                      }
                    , Cmd.none
                    )

        SetQuestionStatus index status ->
            case model.page of
                QuizPage (Quiz.Loaded quiz) ->
                    ( { model
                        | page = QuizPage (Quiz.Loaded (Q.setQuestionStatus index status quiz))
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
            if pageToPath model.page /= Path.fromUrl url then
                let
                    ( newSubModel, cmd ) =
                        initPage url model.cachedQuizzes
                in
                ( { model | page = newSubModel }, cmd )

            else
                ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "20 שאלות"
    , body =
        [ global
            [ Css.Global.body
                [ textAlign right
                , property "direction" "rtl"
                , maxWidth <| calc transitionWidth minus (px 50)
                , margin2 zero auto
                , SharedView.fontSize
                , SharedView.fontFamilies
                ]
            ]
        , body model
        ]
            |> List.map Html.Styled.toUnstyled
    }


body : Model -> Html Msg
body model =
    case model.page of
        QuizListPage subModel ->
            QuizList.body
                model.showErrors
                { showErrors = ShowErrors }
                subModel

        QuizPage subModel ->
            Quiz.body model.showErrors
                { showErrors = ShowErrors
                , setQuestionStatus = SetQuestionStatus
                }
                subModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
