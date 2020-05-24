module Page exposing
    ( Page(..)
    , Path(..)
    , fromState
    , fromUrl
    , href
    , initialStateAndCommand
    , push
    )

import Browser.Navigation as Nav
import Html.Styled
import Html.Styled.Attributes
import Http
import Page.Quiz as Quiz
import Page.QuizList as QuizList
import Quiz exposing (Quiz)
import Url exposing (Url)


type Page
    = QuizListPage QuizList.State
    | QuizPage Quiz.State


type Path
    = RecentQuizzes
    | AQuiz Quiz.Id


fromState : Page -> Path
fromState state =
    case state of
        QuizListPage _ ->
            RecentQuizzes

        QuizPage quizPage ->
            AQuiz (Quiz.quizId quizPage)


fromUrl : Url -> Path
fromUrl url =
    case url.fragment of
        Nothing ->
            RecentQuizzes

        Just "" ->
            RecentQuizzes

        Just quizIdString ->
            AQuiz (Quiz.idFromUrlFragment quizIdString)


toUrl : Path -> String
toUrl page =
    case page of
        RecentQuizzes ->
            "/"

        AQuiz quizId ->
            "/#" ++ Quiz.idUrlFragment quizId


href : Path -> Html.Styled.Attribute msg
href page =
    Html.Styled.Attributes.href (toUrl page)


push : Nav.Key -> Path -> Cmd msg
push key page =
    Nav.pushUrl key (toUrl page)



-- ACTUAL LOGIC


initialStateAndCommand :
    Url
    -> Maybe (List Quiz.Metadata)
    ->
        { getLatestQuizzes : Cmd msg
        , getQuiz : Quiz.Id -> Cmd msg
        }
    -> ( Page, Cmd msg )
initialStateAndCommand url cachedQuizzes cmds =
    case fromUrl url of
        RecentQuizzes ->
            case cachedQuizzes of
                Nothing ->
                    ( QuizListPage QuizList.Loading
                    , cmds.getLatestQuizzes
                    )

                Just quizzes ->
                    ( QuizListPage (QuizList.Loaded quizzes), Cmd.none )

        AQuiz quizId ->
            ( case cachedQuizzes of
                Just quizzes ->
                    quizzes
                        |> List.filter (\{ id } -> id == quizId)
                        |> List.head
                        |> Maybe.map Quiz.LoadingWithMetadata
                        |> Maybe.withDefault (Quiz.Loading quizId)
                        |> QuizPage

                _ ->
                    QuizPage (Quiz.Loading quizId)
            , cmds.getQuiz quizId
            )
