module SharedView exposing
    ( button
    , fontFamilies
    , fontSize
    , httpErrorBody
    , onDesktop
    , onMobile
    , transitionWidth
    )

import Css exposing (..)
import Css.Media as Media exposing (only, screen, withMedia)
import Html.Styled exposing (Html, a, img, p, text)
import Html.Styled.Attributes exposing (css, src)
import Html.Styled.Events exposing (onClick)
import Http
import Path


transitionWidth : Px
transitionWidth =
    px 700


onDesktop : List Style -> Style
onDesktop =
    withMedia [ only screen [ Media.minWidth transitionWidth ] ]


onMobile : List Style -> Style
onMobile =
    withMedia [ only screen [ Media.maxWidth transitionWidth ] ]


fontSize : Style
fontSize =
    Css.fontSize <| px 18


fontFamilies : Style
fontFamilies =
    Css.fontFamilies [ "Helvetica", "Arial" ]


button : Bool -> List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
button isActive =
    Html.Styled.styled Html.Styled.button
        [ padding2 (px 5) (px 10)
        , margin <| zero
        , borderRadius <| px 3
        , textDecoration none
        , border <| px 0
        , if isActive then
            Css.backgroundColor <| hex "4590E6"

          else
            Css.backgroundColor <| hex "B3D7FF"
        , color <| hex "FFFFFF"
        , fontSize
        , fontFamilies
        , property "-webkit-appearence" "none"
        ]


httpErrorBody : Bool -> msg -> Http.Error -> List (Html msg)
httpErrorBody shouldShowErrors onShowErrors err =
    case err of
        Http.NetworkError ->
            [ p [] [ text "השרת לא מגיב" ] ]

        Http.BadUrl url ->
            [ p [] [ text <| "יש בעיה בכתובת הזאת: " ++ url ] ]

        Http.BadStatus 500 ->
            [ p []
                [ text <|
                    "הארץ מעצבנים אז אי אפשר לגשת לשאלון הזה. אחרים (בתקווה) כן יעבדו."
                ]
            , p [] [ a [ Path.href Path.RecentQuizzes ] [ text "שאר השאלונים" ] ]
            ]

        Http.BadStatus code ->
            [ p []
                [ text <|
                    "השרת החזיר את הקוד "
                        ++ String.fromInt code
                        ++ ", מה שזה לא אומר"
                ]
            ]

        Http.Timeout ->
            [ p [] [ text <| "לקח לשרת יותר מדי זמן להגיב" ] ]

        Http.BadBody body_ ->
            if shouldShowErrors then
                [ p [] [ text <| "השרת לא יודע איך להתמודד עם זה:" ]
                , p [] [ text body_ ]
                ]

            else
                [ p [] [ text "השרת שלח לי משהו שאני לא יודע איך להתמודד איתו" ]
                , button True [ onClick onShowErrors ] [ text "זה בסדר, אני דן" ]
                ]
