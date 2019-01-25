module Monitor exposing (application, document, element, sandbox, worker)

import Browser
import Browser.Navigation
import Html
import Url


worker :
    { init : Init flags model msg
    , update : Update msg model
    , subscriptions : model -> Sub msg
    }
    -> Program flags model msg
worker config =
    Platform.worker
        { config
            | init = init config.init
            , update = update config.update
        }


sandbox :
    { init : model
    , view : model -> Html.Html msg
    , update : SandboxUpdate msg model
    }
    -> Program () model msg
sandbox config =
    Browser.sandbox
        { config
            | init = sandboxInit config.init
            , update = sandboxUpdate config.update
        }


element :
    { init : Init flags model msg
    , view : model -> Html.Html msg
    , update : Update msg model
    , subscriptions : model -> Sub msg
    }
    -> Program flags model msg
element config =
    Browser.element
        { config
            | init = init config.init
            , update = update config.update
        }


document :
    { init : Init flags model msg
    , view : model -> Browser.Document msg
    , update : Update msg model
    , subscriptions : model -> Sub msg
    }
    -> Program flags model msg
document config =
    Browser.document
        { config
            | init = init config.init
            , update = update config.update
        }


application :
    { init : ApplicationInit flags model msg
    , view : model -> Browser.Document msg
    , update : Update msg model
    , subscriptions : model -> Sub msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , onUrlChange : Url.Url -> msg
    }
    -> Program flags model msg
application config =
    Browser.application
        { config
            | init = applicationInit config.init
            , update = update config.update
        }



-- helpers


sandboxInit : model -> model
sandboxInit model =
    let
        _ =
            Debug.log "[Monitor:init]" model
    in
    model


type alias SandboxUpdate msg model =
    msg -> model -> model


sandboxUpdate : SandboxUpdate msg model -> SandboxUpdate msg model
sandboxUpdate updater message model =
    let
        result =
            updater message model

        _ =
            Debug.log "[Monitor:update]" ( message, result )
    in
    result


type alias Init flags model msg =
    flags -> ( model, Cmd msg )


init : Init flags model msg -> Init flags model msg
init initializer flags =
    let
        result =
            initializer flags

        _ =
            Debug.log "[Monitor:init]" (Tuple.first result)
    in
    result


type alias Update msg model =
    msg -> model -> ( model, Cmd msg )


update : Update msg model -> Update msg model
update updater message model =
    let
        result =
            updater message model

        _ =
            Debug.log "[Monitor:update]" ( message, Tuple.first result )
    in
    result


type alias ApplicationInit flags model msg =
    flags -> Url.Url -> Browser.Navigation.Key -> ( model, Cmd msg )


applicationInit : ApplicationInit flags model msg -> ApplicationInit flags model msg
applicationInit initializer flags url key =
    let
        result =
            initializer flags url key

        _ =
            Debug.log "[Monitor:init]" (Tuple.first result)
    in
    result
