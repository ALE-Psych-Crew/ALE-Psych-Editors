import flixel.group.FlxTypedSpriteGroup as FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxRect;
import flixel.util.FlxAxes;

import openfl.geom.Rectangle;

import utils.ALEEditorUtil;

import ale.ui.*;

@:typedef CameraData = {
    var x:Float;
    var y:Float;
    var zoom:Float;
};

var xLine:FlxBackdrop;
var yLine:FlxBackdrop;

var cameraView:FlxSprite;

var camViewData:CameraData = {
    x: FlxG.width * 0.1,
    y: 0,
    zoom: 0.75
};

function onCreate()
{
    camGame.zoom = camViewData.zoom;
    camGame.scroll.x = camViewData.x;
    camGame.scroll.y = camViewData.y;

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

    cameraView = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true, '::ALE_PSYCH_STAGE_EDITOR_CAMERA_VIEW_GRAPHIC');

    ALEUIUtils.outlineBitmap(cameraView.pixels, 2);
    
    var crossSize:Int = Math.floor(Math.min(FlxG.width, FlxG.height) / 40);

    var cameraViewRect:Rectangle = new Rectangle();

    cameraViewRect.setTo(FlxG.width / 2 - 1 - crossSize, FlxG.height / 2 - 1, 2 + crossSize * 2, 2);
    cameraView.pixels.fillRect(cameraViewRect, FlxColor.WHITE);

    cameraViewRect.setTo(FlxG.width / 2 - 1, FlxG.height / 2 - 1 - crossSize, 2, 2 + crossSize * 2);
    cameraView.pixels.fillRect(cameraViewRect, FlxColor.WHITE);
        
    cameraView.antialiasing = false;
    cameraView.color = FlxColor.CYAN;
    cameraView.alpha = 0.5;
    add(cameraView);

    createViewTab();
    createDataTab();
}

var cameraViewText:FlxText;

function createViewTab()
{
    var tab:ALETab = new ALETab(FlxG.width - 50, FlxG.height - 125, 350, 90, 'Camera Data');
    add(tab);
    tab.cameras = [camHUD];
    tab.x -= tab.width;

    cameraViewText = new FlxText(20, 20, 0, '', 18);
    cameraViewText.font = ALEUIUtils.FONT;
    tab.add(cameraViewText);
}

var json:StageJSON = {
    zoom: 1
};

function createDataTab()
{
    var tab:ALEMultiTab = new ALEMultiTab(FlxG.width - 50, 50, 350, 300, ['Objects', 'Characters', 'Camera']);
    add(tab);
    tab.cameras = [camHUD];
    tab.curGroup = 'Camera';
    tab.x -= tab.width;
    
    var zoomStepper = ALEEditorUtil.labelStepper(20, 20, 'Zoom', json.zoom, 0.1, 5, 0.1, json, 'zoom', () -> {
        cameraView.scale.x = cameraView.scale.y = 1 / json.zoom;
    });

    tab.addObj('Camera', zoomStepper.label);
    tab.addObj('Camera', zoomStepper.stepper);
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

function updateCameraControls(elapsed:Float)
{
    if (Controls.MOUSE_WHEEL)
    {
        if (ctrlPressed)
        {
            camViewData.zoom += FlxG.mouse.wheel / 10 * camViewData.zoom;

            camViewData.zoom = FlxMath.bound(camViewData.zoom, 0.1, 3);

            xLine.scale.y = 1 / camViewData.zoom;
            yLine.scale.x = 1 / camViewData.zoom;
        } else {
            var factor:Float = -FlxG.mouse.wheel * 50 / camViewData.zoom;

            if (shiftPressed)
                camViewData.x += factor;
            else
                camViewData.y += factor;
        }
    }

    camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, camViewData.zoom, 0.3);

    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, camViewData.x, 0.3);
    camGame.scroll.y = CoolUtil.fpsLerp(camGame.scroll.y, camViewData.y, 0.3);

    cameraViewText.text = 'Scroll: x: ' + Math.floor(camGame.scroll.x) + ' | y: ' + Math.floor(camGame.scroll.y);
    cameraViewText.text += '\nZoom: ' + CoolUtil.floorDecimal(camGame.zoom, 2);
}