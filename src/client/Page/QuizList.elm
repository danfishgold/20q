module Page.QuizList exposing (Model(..), body, init, onResponse, quizzes)

import Css exposing (..)
import Date
import Grid
import Html.Styled exposing (Html, a, div, h2, img, main_, p, styled, text)
import Html.Styled.Attributes exposing (alt, css, src)
import Http
import Path
import Quiz
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


body : Bool -> { showErrors : msg } -> Model -> Html msg
body showErrors msgs model =
    main_
        [ css
            [ Grid.display
            , Grid.rowGap <| px 30
            , padding <| px 30
            , paddingTop <| px 60
            ]
        ]
        (content showErrors msgs model)


h1 =
    styled Html.Styled.h1
        [ margin zero
        ]


content : Bool -> { showErrors : msg } -> Model -> List (Html msg)
content showErrors msgs model =
    case model of
        Loading ->
            [ h1 [] [ text "20 שאלות" ]
            , p [] [ text "רק רגע אחד..." ]
            ]

        Error err ->
            h1 [] [ text "שיט, רגע יש שגיאה" ]
                :: httpErrorBody showErrors msgs.showErrors err

        Loaded quizzes_ ->
            h1 [] [ text "20 שאלות" ]
                :: List.map quizMetadataView quizzes_


quizMetadataView : Quiz.Metadata -> Html msg
quizMetadataView { title, id, image, date } =
    div
        [ css
            [ boxShadow4 (px 0) (px 3) (px 5) (hex "999")
            , overflow hidden
            , borderRadius <| px 5
            ]
        ]
        [ a
            [ Path.href (Path.AQuiz id)
            , css [ textDecoration none, color <| rgb 0 0 0 ]
            ]
            [ img
                [ src image
                , alt ""
                , css [ width <| pct 100 ]
                ]
                []
            , div
                [ css [ padding3 (px 5) (px 20) (px 20) ] ]
                [ h2
                    [ css
                        [ marginBottom <| px 10
                        , marginTop <| px 0
                        ]
                    ]
                    [ text title ]
                , Html.Styled.node "date" [] [ text <| Date.toString date ]
                ]
            ]
        ]
