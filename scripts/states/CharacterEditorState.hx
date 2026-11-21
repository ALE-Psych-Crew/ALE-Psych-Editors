import funkin.visuals.objects.FunkinSprite;
import funkin.visuals.game.Character;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;

import ale.ui.objects.*;
import ale.ui.Config;

import UIUtil;

final uiGroup:FlxGroup;

function postCreate()
{
    camGame.bgColor = FlxColor.GRAY;

    ghost = add(new FunkinSprite());
    ghost.visible = false;
    ghost.alpha = 0.5;

    character = add(new Character('bf'));
    
    uiGroup = new FlxGroup();
    add(uiGroup);

    initSettingsTab();

    initCharacterTab();

    resetCharacter();

    uiGroup.camera = camHUD;
}

final character:Character;
final ghost:FunkinSprite;

function resetCharacter(?name:String = 'bf')
{
    character.change(name);
}

final tabGS:MultiTab;

final tabGSSetReload:Button;
final tabGSSetPlayable:CheckBox;
final tabGSSetDropDown:DropDownMenu;
final tabGSSetSave:DropDownMenu;

final tabGSGhoMake:Button;
final tabGSGhoOpacity:Slider;

function initSettingsTab()
{
    final list = UIUtil.jsonsList('characters');

    tabGS = new MultiTab(1, 1, ['Ghost', 'Settings'], 'Ghost', 12, 5);
    tabGS.place(1, 1, true);
    uiGroup.add(tabGS);

    tabGSGhoMake = new Button(1, 1, 'Make Ghost', () -> {
        if (!ghost.visible)
            ghost.visible = true;

        ghost.loadGraphic(character.graphic);
        ghost.frames.frames = character.frames.frames;
        ghost.animation.copyFrom(character.animation);
        ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
        ghost.animation.pause();

        ghost.setPosition(character.x, character.y);
        ghost.antialiasing = character.antialiasing;
        ghost.flipX = character.flipX;
        ghost.scale.set(character.scale.x, character.scale.y);
        ghost.updateHitbox();
        ghost.offset.set(character.offset.x, character.offset.y);
    }, 10);
    tabGS.addObj('Ghost', tabGSGhoMake);

    tabGSGhoOpacity = new Slider(1, 3, 0, 1, 0.5, true, 10);
    tabGS.addObj('Ghost', tabGSGhoOpacity);
    tabGSGhoOpacity.setTarget(ghost, 'alpha', true);

    tabGSSetReload = new Button(7, 1, 'Reload', null, 4, 1, {color: FlxColor.GRAY});
    tabGS.addObj('Settings', tabGSSetReload);

    tabGSSetPlayable = new CheckBox(1, 3, 'Playable');
    tabGS.addObj('Settings', tabGSSetPlayable);

    tabGSSetDropDown = new DropDownMenu(1, 1, list, list[0], 'Character...', 4);
    tabGS.addObj('Settings', tabGSSetDropDown);

    tabGSSetSave = new Button(7, 3, 'Save', null, 4, 1, {color: FlxColor.CYAN});
    tabGS.addObj('Settings', tabGSSetSave);
}

final tabAC:MultiTab;

final tabACAniDropDown:DropDownMenu;
final tabACAniName:InputText;
final tabACAniPrefix:InputText;
final tabACAniIndices:InputText;
final tabACAniLoop:CheckBox;
final tabACAniFramerate:NumericStepper;

final tabACChaImage:InputText;
final tabACChaIcon:InputText;
final tabACChaCamX:NumericStepper;
final tabACChaCamY:NumericStepper;
final tabACChaPosX:NumericStepper;
final tabACChaPosY:NumericStepper;
final tabACChaScale:NumericStepper;
final tabACChaAntialiasing:CheckBox;
final tabACChaFlipX:CheckBox;

function initCharacterTab()
{
    tabAC = new MultiTab(1, 1, ['Animations', 'Character'], 'Character', 15, 11);
    tabAC.place(1, 8, true);
    uiGroup.add(tabAC);

    tabACAniDropDown = new DropDownMenu(1, 1, ['oso'], 'oso', 'Animation...', 5);
    tabAC.addObj('Animations', tabACAniDropDown);

    tabACAniName = new InputText(8, 1, 'Name...', '', null, 6);
    tabAC.addObj('Animations', tabACAniName);

    tabACAniPrefix = new InputText(1, 3, 'Prefix...', '', null, 6);
    tabAC.addObj('Animations', tabACAniPrefix);

    tabACAniIndices = new InputText(8, 3, 'Indices...', '', null, 6);
    tabAC.addObj('Animations', tabACAniIndices);

    tabACAniLoop = new CheckBox(1, 5, 'Looped');
    tabAC.addObj('Animations', tabACAniLoop);

    tabACAniFramerate = new NumericStepper(8, 5, 0, 100, 24);
    tabAC.addObj('Animations', tabACAniFramerate);

    tabACChaImage = new InputText(1, 1, 'Image...', '', null, 6);
    tabAC.addObj('Character', tabACChaImage);

    tabACChaIcon = new InputText(8, 1, 'Icon...', '', null, 6);
    tabAC.addObj('Character', tabACChaIcon);

    tabACChaPosX = new NumericStepper(1, 5, UIUtil.MIN, UIUtil.MAX);
    tabAC.addObj('Character', tabACChaPosX);
    tabACChaPosX.setTarget(character, 'x', true);

    tabACChaPosY = new NumericStepper(8, 5, UIUtil.MIN, UIUtil.MAX);
    tabAC.addObj('Character', tabACChaPosY);
    tabACChaPosY.setTarget(character, 'y', true);

    tabACChaCamX = new NumericStepper(1, 3, UIUtil.MIN, UIUtil.MAX);
    tabAC.addObj('Character', tabACChaCamX);

    tabACChaCamY = new NumericStepper(8, 3, UIUtil.MIN, UIUtil.MAX);
    tabAC.addObj('Character', tabACChaCamY);

    tabACChaScale = new NumericStepper(1, 7, 0, UIUtil.MAX, null, 0.1);
    tabAC.addObj('Character', tabACChaScale);
    tabACChaScale.setTarget(character.scale, ['x', 'y'], true, val -> {
        character.scale.set(val, val);
        character.updateHitbox();

        debugTrace('oos');
    });

    tabACChaAntialiasing = new CheckBox(1, 9, 'Antialiasing');
    tabAC.addObj('Character', tabACChaAntialiasing);
    tabACChaAntialiasing.value = true;
    tabACChaAntialiasing.setTarget(character, 'antialiasing', true);

    tabACChaFlipX = new CheckBox(8, 9, 'Flip X');
    tabAC.addObj('Character', tabACChaFlipX);
    tabACChaFlipX.setTarget(character, 'flipX', true);

    tabAC.camera = camHUD;
}


function onUpdate(elapsed:Float)
{
    updateCameraControls();

    updateCharacterControls();
}

var charOffset:FlxPoint = FlxPoint.get();
var movingChar:Bool = false;

function updateCharacterControls()
{
    if (Controls.MOUSE_P)
        if (FlxG.mouse.overlaps(character) && !FlxG.mouse.overlaps(uiGroup))
        {
            final mousePos:FlxPoint = FlxG.mouse.getViewPosition(camGame, charOffset);

            charOffset.x -= character.x;
            charOffset.y -= character.y;

            movingChar = true;
        }

    if (Controls.MOUSE_R)
        movingChar = false;

    if (movingChar)
    {
        final mousePos:FlxPoint = FlxG.mouse.getViewPosition(camGame);

        character.setPosition(mousePos.x - charOffset.x, mousePos.y - charOffset.y);

        tabACChaPosX.syncValue();
        tabACChaPosY.syncValue();
    }
}

var camScroll:FlxPoint = FlxPoint.get();
var camMouse:FlxPoint = FlxPoint.get();
var movingCam:Bool = false;

function updateCameraControls()
{
    if (Controls.MOUSE_WHEEL)
        if (Controls.CONTROL)
        {
            camGame.targetZoom = FlxMath.bound(0.1, camGame.targetZoom + FlxG.mouse.wheel * 0.2 * camGame.zoom, 5);
        } else {
            final factor:Float = 50 / camGame.zoom;

            if (Controls.SHIFT)
                camGame.position.x -= FlxG.mouse.wheel * factor;
            else
                camGame.position.y -= FlxG.mouse.wheel * factor;
        }

    if (FlxG.mouse.justPressedMiddle)
    {
        FlxG.mouse.getViewPosition(camGame, camMouse);

        camScroll.set(camGame.position.x, camGame.position.y);

        movingCam = true;
    }

    if (FlxG.mouse.justReleasedMiddle)
        movingCam = false;

    if (movingCam)
    {
        final mousePos:FlxPoint = FlxG.mouse.getViewPosition(camGame);

        camGame.position.set(camScroll.x - (mousePos.x - camMouse.x), camScroll.y - (mousePos.y - camMouse.y));
    }
}

function onDestroy()
{
    charOffset.put();

    camScroll.put();
    camMouse.put();
}