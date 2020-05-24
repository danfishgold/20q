module Page.QuizList exposing (Model(..), body, init, onResponse, quizzes)

import Css exposing (..)
import Date
import Html.Styled exposing (Html, a, div, h1, h2, img, text)
import Html.Styled.Attributes exposing (alt, css, src)
import Http
import Path
import Quiz exposing (Quiz)
import SharedView exposing (httpErrorBody)


type Model
    = Loading
    | Error Http.Error
    | Loaded (List Quiz.Metadata)



-- INIT


init : { handleGetQuizList : Result Http.Error (List Quiz.Metadata) -> msg } -> Maybe (List Quiz.Metadata) -> ( Model, Cmd msg )
init msgs cachedQuizzes =
    case cachedQuizzes of
        Nothing ->
            ( Loading
            , Quiz.getLatestQuizzes msgs.handleGetQuizList
            )

        Just quizzes_ ->
            ( Loaded quizzes_, Cmd.none )



-- HELPERS


onResponse : Result Http.Error (List Quiz.Metadata) -> Model
onResponse response =
    case response of
        Ok quizzes_ ->
            Loaded quizzes_

        Err error ->
            Error error


quizzes : Model -> Maybe (List Quiz.Metadata)
quizzes model =
    case model of
        Loaded quizzes_ ->
            Just quizzes_

        _ ->
            Nothing



-- VIEW


body : Bool -> { showErrors : msg } -> Model -> List (Html msg)
body showErrors msgs model =
    case model of
        Loading ->
            [ h1 [] [ text "20 שאלות" ]
            , text "רק רגע אחד..."
            ]

        Error err ->
            h1 [] [ text "שיט, רגע יש שגיאה" ]
                :: httpErrorBody showErrors msgs.showErrors err

        Loaded quizzes_ ->
            [ h1 [] [ text "20 שאלות" ]
            , div [] (List.map quizMetadataView quizzes_)
            ]


quizMetadataView : Quiz.Metadata -> Html msg
quizMetadataView { title, id, image, date } =
    div
        [ css
            [ boxShadow4 (px 0) (px 3) (px 5) (hex "999")
            , marginTop <| px 30
            , marginBottom <| px 30
            ]
        ]
        [ a
            [ Path.href (Path.AQuiz id)
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
