module Remote exposing (Remote(..), fromResult, get, map)

import Http
import Json.Decode


type Remote data
    = Loading
    | Success data
    | Failure Http.Error


map : (a -> b) -> Remote a -> Remote b
map fn remote =
    case remote of
        Loading ->
            Loading

        Success a ->
            Success (fn a)

        Failure err ->
            Failure err


get : String -> (Remote data -> msg) -> Json.Decode.Decoder data -> Cmd msg
get url toMsg decoder =
    Http.get
        { url = url
        , expect = Http.expectJson (toMsg << fromResult) decoder
        }


fromResult : Result Http.Error data -> Remote data
fromResult result =
    case result of
        Err error ->
            Failure error

        Ok data ->
            Success data
