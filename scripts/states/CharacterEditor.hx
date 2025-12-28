import flixel.group.FlxTypedSpriteGroup as FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxAxes;

import funkin.visuals.objects.HealthIcon;
import funkin.visuals.game.Character;

import openfl.geom.Rectangle;

import utils.ALEEditorUtil;

import ale.ui.*;

using StringTools;

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

var positions = {
    dad: FlxPoint.weak(),
    bf: FlxPoint.weak()
}

var icon:HealthIcon;
var character:Character;

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

    positions.dad = FlxPoint.get(100, 100);
    positions.bf = FlxPoint.get(770, 100);

    var crossSize:Int = Math.floor(Math.min(FlxG.width, FlxG.height) / 40);

    var dad:FlxSprite = new FlxSprite(positions.dad.x, positions.dad.y).loadGraphic(Paths.image('editors/silhouetteDad'));
    dad.active = false;
    dad.offset.set(-4, 1);
    add(dad);
    dad.alpha = 0.5;

    var boyfriend:FlxSprite = new FlxSprite(positions.bf.x, positions.bf.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
    boyfriend.active = false;
    boyfriend.offset.set(-6, 2);
    add(boyfriend);
    boyfriend.alpha = 0.5;

    createViewTab();
    createDataTab();

    loadCharacter(false);
}

var charList:Array<String> = [for (coso in Paths.readDirectory('characters', 'multiple')) coso.substring(0, coso.length - 5)];

var charDrop:ALEDropDownMenu = new ALEDropDownMenu(0, 0, charList);
add(charDrop);
charDrop.value = charList[0];

function loadCharacter(reload:Bool)
{
    var index:Int = reload ? game.members.indexOf(character) : game.members.length;

    if (reload)
        remove(character, true);

    character = null;

    character = new Character(0, 0, charDrop.value, !predIsntPlayer(charDrop.value));
    insert(index, character);
    
    if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
    {
        character.isPlayer = !character.isPlayer;

        character.flipX = character.originalFlipX != character.isPlayer;

        if (check_player != null)
            check_player.checked = character.isPlayer;
    }

    character.debugMode = true;

    /*
    setCharPosition();

    resetUI();

    setCameraPosition();
    */
}

inline function predIsntPlayer(name:String)
    return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) || name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';

var cameraViewText:FlxText;

function createViewTab()
{
    var tab:ALETab = new ALEMultiTab(FlxG.width - 50, FlxG.height - 225, 350, 200, ['Character', 'Camera']);
    add(tab);
    tab.cameras = [camHUD];
    tab.x -= tab.width;

    cameraViewText = new FlxText(20, 20, 0, '', 18);
    cameraViewText.font = ALEUIUtils.FONT;
    tab.addObj('Camera', cameraViewText);
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