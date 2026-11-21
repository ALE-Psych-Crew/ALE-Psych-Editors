package;

import core.enums.ScriptCallType;
import core.visuals.Camera;

import funkin.states.CustomState;
import funkin.visuals.FXCamera;

class UIState extends CustomState
{
    override function initCameras()
    {
        if (scriptsManager.callback(ScriptCallType.ON, 'CamerasInit'))
        {
            camGame = new FXCamera();
            camGame.zoomSpeed = camGame.speed = 5;

            FlxG.cameras.reset(camGame);
            FlxG.cameras.setDefaultDrawTarget(camGame, true);

            camHUD = new Camera();

            FlxG.cameras.add(camHUD, false);
        }

        scriptsManager.callback(ScriptCallType.POST, 'CamerasInit');
    }

    override public function reset()
    {
        allowMemoryCleaning = false;

        CoolUtil.switchState(new UIState(name, scriptsManager.globalArguments, scriptsManager.haxeArguments), true, true);
    }
}