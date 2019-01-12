module Main exposing (main)

import Browser exposing (document)


type alias Model =
    {}


type Msg
    = Msg


main : Program () Model Msg
main =
    document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init () =
    ( {}, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "20 שאלות", body = [] }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
