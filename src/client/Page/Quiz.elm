module Page.Quiz exposing (State(..), onResponse, quizId)

import Http
import Quiz exposing (Quiz)


type State
    = Loading Quiz.Id
    | LoadingWithMetadata Quiz.Metadata
    | Error Quiz.Id Http.Error
    | Loaded Quiz


quizId : State -> Quiz.Id
quizId pageState =
    case pageState of
        Loading id ->
            id

        LoadingWithMetadata { id } ->
            id

        Error id _ ->
            id

        Loaded { metadata } ->
            metadata.id


onResponse : Result Http.Error Quiz -> State -> State
onResponse result state =
    let
        id =
            quizId state
    in
    case result of
        Ok quiz ->
            if quiz.metadata.id == id then
                Loaded quiz

            else
                state

        Err error ->
            Error id error
