module Date exposing (Date, decoder, toString)

import Json.Decode as Json
import Time exposing (Month(..))


type Date
    = Date Time.Posix


decoder : Json.Decoder Date
decoder =
    Json.map ((*) 1000 >> Time.millisToPosix >> Date) Json.int


toString : Date -> String
toString (Date posix) =
    let
        day =
            Time.toDay Time.utc posix

        month =
            Time.toMonth Time.utc posix

        year =
            Time.toYear Time.utc posix
    in
    String.fromInt day ++ " ב" ++ monthToString month ++ ", " ++ String.fromInt year


monthToString : Time.Month -> String
monthToString month =
    case month of
        Jan ->
            "ינואר"

        Feb ->
            "פברואר"

        Mar ->
            "מרץ"

        Apr ->
            "אפריל"

        May ->
            "מאי"

        Jun ->
            "יוני"

        Jul ->
            "יולי"

        Aug ->
            "אוגוסט"

        Sep ->
            "ספטמבר"

        Oct ->
            "אוקטובר"

        Nov ->
            "נובמבר"

        Dec ->
            "דצמבר"
