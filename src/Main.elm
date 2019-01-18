module Main exposing (main)

import Array exposing (Array)
import Browser exposing (document)
import Css exposing (..)
import Css.Global exposing (..)
import Css.Media as Media exposing (only, screen, withMedia)
import Html.Styled exposing (Html, button, div, h1, h2, img, p, span, text)
import Html.Styled.Attributes exposing (css, src, style)
import Html.Styled.Events exposing (onClick)
import Http
import Json.Decode as Json
import Remote exposing (Remote)


type alias Model =
    { quiz : Remote Quiz
    , showErrors : Bool
    }


type alias Quiz =
    { title : String
    , image : Maybe String
    , questions : Array Question
    }


type alias Question =
    { question : String
    , answer : String
    , status : QuestionStatus
    }


type QuestionStatus
    = AnswerHidden
    | AnswerShown
    | Answered Score


type Score
    = Correct
    | Incorrect
    | Half


type Msg
    = HandleGetQuiz (Remote Quiz)
    | SetQuestionStatus Int QuestionStatus
    | ShowErrors


main : Program () Model Msg
main =
    document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


finalScore : Quiz -> Maybe Float
finalScore quiz =
    quiz.questions
        |> Array.toList
        |> List.map (.status >> statusToScoreValue)
        |> flatten
        |> Maybe.map List.sum


flatten : List (Maybe a) -> Maybe (List a)
flatten maybes =
    case maybes of
        [] ->
            Just []

        Nothing :: _ ->
            Nothing

        (Just hd) :: tl ->
            case flatten tl of
                Nothing ->
                    Nothing

                Just tl_ ->
                    Just (hd :: tl_)


statusToScoreValue : QuestionStatus -> Maybe Float
statusToScoreValue status =
    case status of
        Answered score ->
            Just (scoreToFloat score)

        _ ->
            Nothing


scoreToFloat : Score -> Float
scoreToFloat score =
    case score of
        Correct ->
            1

        Incorrect ->
            0

        Half ->
            0.5


quizDecoder : QuestionStatus -> Json.Decoder Quiz
quizDecoder questionStatus =
    Json.map3 Quiz
        (Json.field "title" Json.string)
        (Json.field "image" Json.string |> Json.maybe)
        (Json.field "questions" <| Json.array <| questionDecoder questionStatus)


questionDecoder : QuestionStatus -> Json.Decoder Question
questionDecoder status =
    Json.map2 (\q a -> Question q a status)
        (Json.field "question" Json.string)
        (Json.field "answer" Json.string)


init : () -> ( Model, Cmd Msg )
init () =
    ( { quiz = Remote.Loading
      , showErrors = False
      }
    , Remote.get "https://20q.glitch.me/latest_quiz"
        HandleGetQuiz
        (quizDecoder AnswerHidden)
    )


fakeQuiz =
    { image = Just "https://images.haarets.co.il/image/upload/w_500,h_290,x_0,y_17,c_crop,g_north_west/w_640,h_370,q_auto,c_fill,f_auto/fl_lossy.any_format.preserve_transparency.progressive:none/v1546520298/1.6806950.4030303706.gif"
    , questions =
        Array.fromList
            [ { answer = "גַּלְגֶּשֶׁת"
              , question = "בלועזית סקייטבורד, ובעברית?"
              , status = AnswerHidden
              }
            , { answer = "קרדיט"
              , question = "בעברית מִזְכֶּה, ובלועזית?"
              , status = AnswerHidden
              }
            , { answer = "בתלמוד: על עבד או שפחה שאדונם היכה אותם וגרם להם נזק גופני חמור"
              , question = "באיזה הקשר נוצר הביטוי \"לצאת בשן ועין\"?"
              , status = AnswerHidden
              }
            , { answer = "בעקבות ספרו של וולף, \"אש וזעם\", שעסק בממשל טראמפ"
              , question = "בעקבות מה כינה דונלד טראמפ את מייקל וולף \"לוזר גמור\"?"
              , status = AnswerHidden
              }
            , { answer = "קרב קונקורד בתחילת מלחמת העצמאות האמריקאית. בשיר \"המנון קונקורד\" מאת אמרסון"
              , question = "על איזה אירוע נכתב במקור המשפט \"הירייה שנשמעה ברחבי העולם\"?"
              , status = AnswerHidden
              }
            , { answer = "סרייבו. רצח הארכידוכס פרנץ פרדיננד ואשתו סופיה ב-1914"
              , question = "באיזו עיר התרחש הרצח שהצית את מלחמת העולם הראשונה?"
              , status = AnswerHidden
              }
            , { answer = "ממפיס, טנסי"
              , question = "באיזו עיר נרצח מרטין לותר קינג ב-1968?"
              , status = AnswerHidden
              }
            , { answer = "אנטנת הרדיו של ורשה בפולין"
              , question = "מה היה המבנה הגבוה ביותר בעולם, עד שקרס ב-1991?"
              , status = AnswerHidden
              }
            , { answer = "צמחי בננה"
              , question = "במה פוגעת מחלת פנמה?"
              , status = AnswerHidden
              }
            , { answer = "קוּק"
              , question = "מה משותף למנכ\"ל חברת אפל, קבוצת איים באוקיינוס השקט והרב הראשי הראשון?"
              , status = AnswerHidden
              }
            , { answer = "בואי נשתטה ונתחתן"
              , question = "מהי השורה האחרונה בשיר \"להשתטות לפעמים\", שהתפרסם בביצוע גבי שושן?"
              , status = AnswerHidden
              }
            , { answer = "אביב"
              , question = "איך קוראים לילד בשיר \"עונות\", ששר אביב גפן?"
              , status = AnswerHidden
              }
            , { answer = "ג'רי מגווייר, שבו שיחקה רנה זלווגר"
              , question = "בעקבות איזה סרט כתב אריאל הורוביץ את השיר \"רנה\"?"
              , status = AnswerHidden
              }
            , { answer = "פני צלקת. נאמר על ידי הדמות שמשחק אל פאצ'ינו"
              , question = "באיזה סרט נאמר המשפט \"תגידו שלום לחבר הקטן שלי\"?"
              , status = AnswerHidden
              }
            , { answer = "כוח סיירות חוקר"
              , question = "מה פשר ראשי התיבות של חבורת כס\"ח בסדרת הספרים מאת גלילה רון־פדר?"
              , status = AnswerHidden
              }
            , { answer = "ארץ יצורי הפרא מאת מוריס סנדק, שבמקור נועד להיקרא \"ארץ סוסי הפרא\""
              , question = "שמו של איזה ספר ידוע הוחלף מפני שמחברו לא ידע לצייר סוסים?"
              , status = AnswerHidden
              }
            , { answer = "סדרת ספרי \"דמדומים\" מאת סטפני מאייר"
              , question = "50 גוונים של אפור מאת אי.אל. ג'יימס התחיל בתור פאנפיקשן (ספרות מעריצים). של איזו יצירה?"
              , status = AnswerHidden
              }
            , { answer = "חברים"
              , question = "בסדרה \"סיפורה של שפחה\", באיזו סדרת טלוויזיה משנות ה-90 צופה שלפרד במחבוא?"
              , status = AnswerHidden
              }
            , { answer = "תרגיע של לארי דיוויד"
              , question = "באיזו סדרה מנסה הדמות הראשית להפיק מחזמר בשם \"פתווה!\" על סלמן רושדי?"
              , status = AnswerHidden
              }
            , { answer = "טאו טאו"
              , question = "איזו סדרה עוסקת בדוב פנדה שאמו נוהגת לספר לו סיפורים?"
              , status = AnswerHidden
              }
            , { answer = "חנה דרזנר"
              , question = "מה שמה המקורי של הזמרת אילנית?"
              , status = AnswerHidden
              }
            ]
    , title = "באיזו עיר נרצח מרטין לותר קינג ב-1968?"
    }


fake () =
    ( { quiz = Remote.Success fakeQuiz }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleGetQuiz quiz ->
            ( { model | quiz = quiz }, Cmd.none )

        SetQuestionStatus index status ->
            ( { model
                | quiz =
                    Remote.map (setQuestionStatus index status)
                        model.quiz
              }
            , Cmd.none
            )

        ShowErrors ->
            ( { model | showErrors = True }, Cmd.none )


setQuestionStatus : Int -> QuestionStatus -> Quiz -> Quiz
setQuestionStatus index newStatus quiz =
    case Array.get index quiz.questions of
        Nothing ->
            quiz

        Just question ->
            let
                newQuestion =
                    { question | status = newStatus }

                newQuestions =
                    Array.set index newQuestion quiz.questions
            in
            { quiz | questions = newQuestions }


transitionWidth =
    px 700


view : Model -> Browser.Document Msg
view model =
    { title = "20 שאלות"
    , body =
        [ global
            [ everything
                [ fontFamilies [ "Helvetica", "Arial" ]
                ]
            ]
        , Html.Styled.node "main"
            [ css
                [ textAlign right
                , property "direction" "rtl"
                , width <| pct 95
                , maxWidth <| transitionWidth
                , marginLeft <| auto
                , marginRight <| auto
                , fontSize <| rem 1.2
                ]
            ]
            (body model)
        ]
            |> List.map Html.Styled.toUnstyled
    }


body : Model -> List (Html Msg)
body model =
    case model.quiz of
        Remote.Loading ->
            [ h1 [] [ text "20 שאלות, והכותרת היא:" ], text "רק רגע אחד..." ]

        Remote.Failure err ->
            httpErrorBody model.showErrors err

        Remote.Success quiz ->
            quizBody quiz


httpErrorBody : Bool -> Http.Error -> List (Html Msg)
httpErrorBody showErrors err =
    let
        wrapper elements =
            h1 [] [ text "20 שאלות והכותרת היא: שיט, רגע יש שגיאה" ] :: elements
    in
    case err of
        Http.NetworkError ->
            wrapper [ p [] [ text "השרת לא מגיב" ] ]

        Http.BadUrl url ->
            wrapper [ p [] [ text <| "יש בעיה בכתובת הזאת: " ++ url ] ]

        Http.BadStatus code ->
            wrapper [ p [] [ text <| "השרת החזיר את הקוד " ++ String.fromInt code ++ ", מה שזה לא אומר" ] ]

        Http.Timeout ->
            wrapper [ p [] [ text <| "לקח לשרת יותר מדי זמן להגיב" ] ]

        Http.BadBody body_ ->
            if showErrors then
                wrapper
                    [ p [] [ text <| "השרת לא יודע איך להתמודד עם זה:" ]
                    , p [] [ text body_ ]
                    ]

            else
                wrapper
                    [ p [] [ text <| "השרת שלח לי משהו שאני לא יודע איך להתמודד איתו" ]
                    , button [ onClick ShowErrors ] [ text "זה בסדר, אני דן" ]
                    ]


quizBody : Quiz -> List (Html Msg)
quizBody quiz =
    [ h1 [] [ text <| "20 שאלות, והכותרת היא: " ++ quiz.title ]
    , case quiz.image of
        Just image ->
            img
                [ src image
                , css
                    [ withMedia [ only screen [ Media.maxWidth transitionWidth ] ]
                        [ Css.width <| vw 100
                        , position relative
                        , left <| pct 50
                        , right <| pct 50
                        , marginLeft <| vw -50
                        , marginRight <| vw -50
                        ]
                    , withMedia [ only screen [ Media.minWidth transitionWidth ] ]
                        [ width <| pct 100
                        ]
                    ]
                ]
                []

        Nothing ->
            text ""
    , div
        [ css
            [ property "display" "grid"
            ]
        ]
        (Array.toList quiz.questions
            |> List.indexedMap questionView
        )
    , case finalScore quiz of
        Nothing ->
            text ""

        Just score ->
            h2 []
                [ text <|
                    "התוצאה הסופית: "
                        ++ String.fromFloat score
                        ++ " תשובות נכונות."
                ]
    ]


questionView : Int -> Question -> Html Msg
questionView index { question, answer, status } =
    let
        col start end =
            css
                [ property
                    "grid-column"
                    (String.fromInt start ++ " / " ++ String.fromInt end)
                , property "align-self" "start"
                ]

        row attrs children =
            div
                (css
                    [ property "display" "grid"
                    , property "grid-template-columns" "2em 1fr 4em"
                    , paddingTop <| px 10
                    , paddingBottom <| px 10
                    ]
                    :: attrs
                )
                children

        questionNumberSpan =
            span [ col 1 2 ] [ text <| String.fromInt (index + 1) ++ "." ]

        questionSpan =
            span [ col 2 3 ] [ text question ]

        showAnswerButton =
            button
                [ col 3 4
                , onClick (SetQuestionStatus index AnswerShown)
                ]
                [ text "תשובה" ]

        answerSpan =
            span [ col 2 3, style "background" "#eee", css [ padding <| px 10 ] ] [ text answer ]

        answerOptionsRow =
            [ Correct, Half, Incorrect ]
                |> List.map (setScoreButton (Answered >> SetQuestionStatus index))
                |> div [ col 2 3 ]
    in
    case status of
        AnswerHidden ->
            row [] [ questionNumberSpan, questionSpan, showAnswerButton ]

        AnswerShown ->
            row []
                [ questionNumberSpan
                , questionSpan
                , answerSpan
                , answerOptionsRow
                ]

        Answered score ->
            row [ style "background" (backgroundColor score) ]
                [ questionNumberSpan, questionSpan ]


setScoreButton : (Score -> msg) -> Score -> Html msg
setScoreButton toMsg score =
    button
        [ onClick <| toMsg score ]
        [ text <| setScoreButtonText score ]


setScoreButtonText : Score -> String
setScoreButtonText score =
    case score of
        Correct ->
            "נכון"

        Incorrect ->
            "לא נכון"

        Half ->
            "חצי נקודה"


backgroundColor : Score -> String
backgroundColor score =
    case score of
        Correct ->
            "lightgreen"

        Incorrect ->
            "pink"

        Half ->
            "yellow"


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
