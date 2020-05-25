module Grid exposing
    ( column
    , column2
    , columnGap
    , display
    , fr
    , row
    , rowGap
    , templateColumns
    , templateRows
    )

import Css exposing (Compatible, Style, property)


display : Style
display =
    property "display" "grid"


templateRows : List String -> Style
templateRows rows =
    property "grid-template-rows" (rows |> String.join " ")


templateColumns : List String -> Style
templateColumns columns =
    property "grid-template-columns" (columns |> String.join " ")


row : Int -> Style
row row_ =
    property "grid-row" (String.fromInt row_)


row2 : Int -> Int -> Style
row2 from to =
    property "grid-row" (String.fromInt from ++ " / " ++ String.fromInt to)


column : Int -> Style
column column_ =
    property "grid-column" (String.fromInt column_)


column2 : Int -> Int -> Style
column2 from to =
    property "grid-column" (String.fromInt from ++ " / " ++ String.fromInt to)


columnGap : Css.Length compatible units -> Style
columnGap { value } =
    property "grid-column-gap" value


rowGap : Css.Length compatible units -> Style
rowGap { value } =
    property "grid-row-gap" value


fr : Float -> { value : String }
fr fr_ =
    { value = String.fromFloat fr_ ++ "fr" }
