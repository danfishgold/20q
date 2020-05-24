module Page exposing
    ( Page(..)
    , QuizListPageState(..)
    , QuizPageState(..)
    , State(..)
    , fromState
    , fromUrl
    , href
    , initialStateAndCommand
    , push
    , quizPageId
    )

import Browser.Navigation as Nav
import Html.Styled
import Html.Styled.Attributes
import Http
import Quiz exposing (Quiz)
import Url exposing (Url)


type State
    = QuizListPage QuizListPageState
    | QuizPage QuizPageState


type QuizPageState
    = LoadingQuiz Quiz.Id
    | LoadingQuizWithMetadata Quiz.Metadata
    | QuizError Quiz.Id Http.Error
    | LoadedQuiz Quiz


type QuizListPageState
    = LoadingQuizList
    | QuizListError Http.Error
    | LoadedQuizList (List Quiz.Metadata)


type Page
    = QuizList
    | AQuiz Quiz.Id


fromState : State -> Page
fromState state =
    case state of
        QuizListPage _ ->
            QuizList

        QuizPage quizPage ->
            AQuiz (quizPageId quizPage)


fromUrl : Url -> Page
fromUrl url =
    case url.fragment of
        Nothing ->
            QuizList

        Just "" ->
            QuizList

        Just quizIdString ->
            AQuiz (Quiz.idFromUrlFragment quizIdString)


toUrl : Page -> String
toUrl page =
    case page of
        QuizList ->
            "/"

        AQuiz quizId ->
            "/#" ++ Quiz.idUrlFragment quizId


href : Page -> Html.Styled.Attribute msg
href page =
    Html.Styled.Attributes.href (toUrl page)


push : Nav.Key -> Page -> Cmd msg
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
    -> ( State, Cmd msg )
initialStateAndCommand url cachedQuizzes cmds =
    case fromUrl url of
        QuizList ->
            case cachedQuizzes of
                Nothing ->
                    ( QuizListPage LoadingQuizList
                    , cmds.getLatestQuizzes
                    )

                Just quizzes ->
                    ( QuizListPage (LoadedQuizList quizzes), Cmd.none )

        AQuiz quizId ->
            ( case cachedQuizzes of
                Just quizzes ->
                    quizzes
                        |> List.filter (\{ id } -> id == quizId)
                        |> List.head
                        |> Maybe.map LoadingQuizWithMetadata
                        |> Maybe.withDefault (LoadingQuiz quizId)
                        |> QuizPage

                _ ->
                    QuizPage (LoadingQuiz quizId)
            , cmds.getQuiz quizId
            )


quizPageId : QuizPageState -> Quiz.Id
quizPageId pageState =
    case pageState of
        LoadingQuiz id ->
            id

        LoadingQuizWithMetadata { id } ->
            id

        QuizError id _ ->
            id

        LoadedQuiz { metadata } ->
            metadata.id
