module Page.QuizList exposing (State(..), onResponse, quizzes)

import Http
import Quiz exposing (Quiz)


type State
    = Loading
    | Error Http.Error
    | Loaded (List Quiz.Metadata)


onResponse : Result Http.Error (List Quiz.Metadata) -> State
onResponse result =
    case result of
        Ok quizzes_ ->
            Loaded quizzes_

        Err error ->
            Error error


quizzes : State -> Maybe (List Quiz.Metadata)
quizzes state =
    case state of
        Loaded quizzes_ ->
            Just quizzes_

        _ ->
            Nothing
