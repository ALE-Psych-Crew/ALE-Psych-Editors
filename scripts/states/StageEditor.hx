import flixel.group.FlxTypedSpriteGroup as FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxRect;
import flixel.util.FlxAxes;

import ale.ui.*;

@:typedef CameraData = {
    var x:Float;
    var y:Float;
    var zoom:Float;
};

var xLine:FlxBackdrop;
var yLine:FlxBackdrop;

function onCreate()
{
    camGame.zoom = 0.75;

    xLine = new FlxBackdrop(null, FlxAxes.X);
    xLine.makeGraphic(FlxG.width, 2, FlxColor.RED);
    xLine.y = -1;
    xLine.alpha = 0.5;
    add(xLine);

    yLine = new FlxBackdrop(null, FlxAxes.Y);
    yLine.makeGraphic(2, FlxG.height, FlxColor.BLUE);
    yLine.x = -1;
    yLine.alpha = 0.5;
    add(yLine);

    var cameraView:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
    ALEUIUtils.outlineBitmap(cameraView.pixels, 2);
    cameraView.dirty = true;
    cameraView.color = FlxColor.CYAN;
    cameraView.alpha = 0.5;
    add(cameraView);

    createViewTab();
    createDataTab();
}

var cameraDataText:FlxText;

function createViewTab()
{
    var tab:ALETab = new ALETab(50, FlxG.height - 140, 350, 90, 'Camera Data');
    add(tab);
    tab.cameras = [camHUD];

    cameraDataText = new FlxText(20, 20, 0, '', 18);
    cameraDataText.font = ALEUIUtils.FONT;
    tab.add(cameraDataText);
}

function createDataTab()
{
    var tab:ALEMultiTab = new ALEMultiTab(50, 50, 350, 300, ['Objects', 'Characters', 'Camera']);
    add(tab);
    tab.cameras = [camHUD];
    tab.curGroup = 'Camera';

    
}

var ctrlPressed(get, never):Bool;
function get_ctrlPressed():Bool
    return FlxG.keys.pressed.CONTROL;

var shiftPressed(get, never):Bool;
function get_shiftPressed():Bool
    return FlxG.keys.pressed.SHIFT;

function onUpdate(elapsed:Float)
{
    updateCameraControls(elapsed);
}

var camData:CameraData = {
    x: 0,
    y: 0,
    zoom: 0.75
};

function updateCameraControls(elapsed:Float)
{
    if (Controls.MOUSE_WHEEL)
    {
        if (ctrlPressed)
        {
            camData.zoom += FlxG.mouse.wheel / 10;

            camData.zoom = FlxMath.bound(camData.zoom, 0.1, 3);

            xLine.scale.y = 1 / camData.zoom;
            yLine.scale.x = 1 / camData.zoom;
        } else {
            var factor:Float = -FlxG.mouse.wheel * 50 / camData.zoom;

            if (shiftPressed)
                camData.x += factor;
            else
                camData.y += factor;
        }
    }

    camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, camData.zoom, 0.3);

    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, camData.x, 0.3);
    camGame.scroll.y = CoolUtil.fpsLerp(camGame.scroll.y, camData.y, 0.3);

    cameraDataText.text = 'Scroll: x: ' + Math.floor(camGame.scroll.x) + ' | y: ' + Math.floor(camGame.scroll.y);
    cameraDataText.text += '\nZoom: ' + CoolUtil.floorDecimal(camGame.zoom, 2);
}