module Path exposing
    ( Path(..)
    , fromUrl
    , href
    , push
    )

import Browser.Navigation as Nav
import Html.Styled
import Html.Styled.Attributes
import Quiz
import Url exposing (Url)


type Path
    = RecentQuizzes
    | AQuiz Quiz.Id


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
