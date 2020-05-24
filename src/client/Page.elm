module Page exposing
    ( Page(..)
    , State(..)
    , fromState
    , fromUrl
    , href
    , initialStateAndCommand
    , loadingQuizId
    , push
    )

import Browser.Navigation as Nav
import Html.Styled
import Html.Styled.Attributes
import Http
import Quiz exposing (Quiz)
import Url exposing (Url)


type State
    = LoadingQuizListPage
    | QuizListPageError Http.Error
    | QuizListPage (List Quiz.Metadata)
    | LoadingQuizPageWithId Quiz.Id
    | LoadingQuizPageWithMetadata Quiz.Metadata
    | QuizPageError Quiz.Id Http.Error
    | QuizPage Quiz


type Page
    = QuizList
    | AQuiz Quiz.Id


fromState : State -> Page
fromState state =
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

        QuizPage { metadata } ->
            AQuiz metadata.id


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
                    ( LoadingQuizListPage
                    , cmds.getLatestQuizzes
                    )

                Just quizzes ->
                    ( QuizListPage quizzes, Cmd.none )

        AQuiz quizId ->
            ( case cachedQuizzes of
                Just quizzes ->
                    quizzes
                        |> List.filter (\{ id } -> id == quizId)
                        |> List.head
                        |> Maybe.map LoadingQuizPageWithMetadata
                        |> Maybe.withDefault (LoadingQuizPageWithId quizId)

                _ ->
                    LoadingQuizPageWithId quizId
            , cmds.getQuiz quizId
            )


loadingQuizId : State -> Maybe Quiz.Id
loadingQuizId pageState =
    case pageState of
        LoadingQuizPageWithId id ->
            Just id

        LoadingQuizPageWithMetadata { id } ->
            Just id

        _ ->
            Nothing
