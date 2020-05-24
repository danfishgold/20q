module Icons exposing (half, v, x)

import Css exposing (paddingLeft, paddingRight, px)
import Html.Styled exposing (Html, span)
import Html.Styled.Events exposing (onClick)
import Svg.Styled exposing (Svg, circle, g, path, polyline, svg)
import Svg.Styled.Attributes
    exposing
        ( css
        , cx
        , cy
        , d
        , fill
        , height
        , id
        , points
        , r
        , stroke
        , strokeLinecap
        , strokeLinejoin
        , strokeWidth
        , transform
        , viewBox
        , width
        )


wrapper : msg -> Svg msg -> Html msg
wrapper clickMsg element =
    span
        [ onClick clickMsg
        , css
            [ Css.width <| px 35
            , Css.height <| px 35
            , paddingLeft <| px 5
            , paddingRight <| px 5
            ]
        ]
        [ element ]


half : msg -> Svg msg
half clickMsg =
    wrapper clickMsg <|
        svg [ height "35px", viewBox "0 0 60 60", width "35px" ]
            [ g [ fill "none", stroke "none", strokeWidth "1" ]
                [ circle
                    [ cx "30", cy "30", fill "#FFD966", id "Oval-Copy-4", r "30" ]
                    []
                , Svg.Styled.path [ d "M51.0027777,8.99722231 L8.99702411,51.0029759", id "Path-2-Copy-6", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "5" ]
                    []
                , polyline
                    [ id "Line-Copy", points "18 15 22.3008294 9 22.3008294 25", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "5" ]
                    []
                , Svg.Styled.path [ d "M35,38.4177734 C35,32.4825321 43.8759133,32.5724573 43.8759133,38.4177734 C43.8759133,41.5840496 35,50.3031989 35,50.3031989 L45,50.3031989", id "Path-3-Copy", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "5" ]
                    []
                ]
            ]


v : msg -> Svg msg
v clickMsg =
    wrapper clickMsg <|
        svg [ height "35px", viewBox "0 0 60 60", width "35px" ]
            [ g [ fill "none", stroke "none", strokeWidth "1" ]
                [ circle
                    [ cx "30", cy "30", fill "#B8E68A", id "Oval-2", r "30" ]
                    []
                , polyline
                    [ id "Path-4", points "47.09319 19 22.1540846 43.9391053 13 34.789978", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "6" ]
                    []
                ]
            ]


x : msg -> Svg msg
x clickMsg =
    wrapper clickMsg <|
        svg [ height "35px", viewBox "0 0 60 60", width "35px" ]
            [ g [ fill "none", stroke "none", strokeWidth "1" ]
                [ circle
                    [ cx "30", cy "30", fill "#FF9999", id "Oval-2-Copy", r "30" ]
                    []
                , Svg.Styled.path [ d "M42.9391053,18 L18,42.9391053", id "Path-4-Copy", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "6" ]
                    []
                , Svg.Styled.path [ d "M42.9391053,18 L18,42.9391053", id "Path-4-Copy-2", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "6", transform "translate(30.469553, 30.469553) scale(-1, 1) translate(-30.469553, -30.469553) " ]
                    []
                ]
            ]
