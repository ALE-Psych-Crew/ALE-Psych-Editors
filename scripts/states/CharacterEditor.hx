import ale.ui.ALEButton;
import ale.ui.ALEDropDown;
import ale.ui.ALETab;
import ale.ui.ALEMultiTab;
import ale.ui.ALENumericStepper;
import ale.ui.ALECircleButton;
import ale.ui.ALEColorPicker;
import ale.ui.ALEInputText;
import ale.ui.ALEUIUtils;

import funkin.visuals.game.Character;

import funkin.visuals.objects.HealthIcon;
import funkin.visuals.objects.Bar;

using StringTools;

WindowsAPI.setWindowBorderColor(33, 33, 33);

add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.GRAY));

var charactersList:Array<String> = [];
var iconsList:Array<String> = [];

public var character:Character;

public var followPointer:FlxSprite;

public var ghost:FlxSprite;

public var icon:HealthIcon;
public var bar:Bar;

public var charTab:ALEMultiTab;

// Character

public var imageFile:ALEInputText;
public var reloadImage:ALEButton;
public var voicesPostfix:ALEInputText;
public var antialiasing:ALECircleButton;
public var flipX:ALECircleButton;
public var animationLength:ALENumericStepper;
public var scale:ALENumericStepper;
public var charX:ALENumericStepper;
public var charY:ALENumericStepper;
public var camX:ALENumericStepper;
public var camY:ALENumericStepper;

// Icon

public var iconName:ALEInputText;
public var barColor:ALEColorPicker;
public var loseIcon:ALECircleButton;

// Animation

public var animList:ALEDropDown;
public var animName:ALEInputText;
public var animSymbol:ALEInputText;
public var animIndices:ALEInputText;
public var animFramerate:ALENumericStepper;
public var animLoop:ALECircleButton;
public var animUpdate:ALEButton;
public var animDelete:ALEButton;

public var miscTab:ALEMultiTab;

// Ghost

public var addGhost:ALEButton;
public var highlightGhost:ALECircleButton;

// Settings

public var charDrop:ALEDropDown;
public var isPlayer:ALECircleButton;

// Save

public var saveName:ALEInputText;
public var saveButton:ALEButton;

function onCreate()
{
    charactersList = readDirectories('characters', '.json');

    iconsList = readDirectories('images/icons', '.png');

    createCharTab();
    
    createMiscTab();

    loadBG();

    followPointer = new FlxSprite().makeGraphic(10, 10, FlxColor.BLACK);
    ALEUIUtils.outlineBitmap(followPointer.pixels);

    bar = new Bar(30, FlxG.height - 75);
    bar.scrollFactor.set();
    add(bar);
    bar.cameras = [game.camHUD];

    ghost = new FlxSprite();
    add(ghost);

    loadCharacter(false);

    icon = new HealthIcon(character.healthIcon, false, false);
    icon.y = FlxG.height - 150;
    add(icon);
    icon.cameras = [game.camHUD];

    add(followPointer);
}

var canSelect:Bool = true;

function onUpdate(elapsed:Float)
{
    if (canSelect && !ALEUIUtils.usingInputs)
    {
        if (FlxG.keys.justPressed.SPACE)
            character.playAnim(animList.selected, true);

        if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
        {
            var index:Int = animList.selectedIndex;
            var max:Int = animList.options.length - 1;

            if (FlxG.keys.justPressed.W)
                if (index <= 0)
                    index = max;
                else
                    index--;

            if (FlxG.keys.justPressed.S)
                if (index >= max)
                    index = 0;
                else
                    index++;

            animList.selected = animList.options[index];
            animList.selectedIndex = index;

            character.playAnim(animList.selected, true);

            resetAnimationUI();
        }
    }
}

final BF_POSITION:Array<Float> = [770, 100];
final DAD_POSITION:Array<Float> = [100, 100];

function loadBG()
{
    var dad:FlxSprite = new FlxSprite(DAD_POSITION[0] + 4, DAD_POSITION[1] - 1).loadGraphic(Paths.image('editors/silhouetteDad'));
    dad.antialiasing = ClientPrefs.data.antialiasing;
    dad.active = false;
    add(dad);
    dad.alpha = 0.5;

    var boyfriend:FlxSprite = new FlxSprite(BF_POSITION[0] + 6, BF_POSITION[1] + 348).loadGraphic(Paths.image('editors/silhouetteBF'));
    boyfriend.antialiasing = ClientPrefs.data.antialiasing;
    boyfriend.active = false;
    add(boyfriend);
    boyfriend.alpha = 0.5;
}

function loadCharacter(reload:Bool)
{
    var index:Int = reload ? game.members.indexOf(character) : game.members.length;

    if (reload)
        remove(character, true);

    character = null;

    character = new Character(0, 0, charDrop.selected, !predIsntPlayer(charDrop.selected));
    insert(index, character);
    
    if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
    {
        character.isPlayer = !character.isPlayer;

        character.flipX = character.originalFlipX != character.isPlayer;

        if (check_player != null)
            check_player.checked = character.isPlayer;
    }

    character.debugMode = true;

    setCharPosition();

    resetUI();

    setCameraPosition();
}

inline function predIsntPlayer(name:String)
    return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) || name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';

function createCharTab()
{
    charTab = new ALEMultiTab(['Icon', 'Animation', 'Character'], 0, 180, 500, 300);
    charTab.x = FlxG.width - charTab.width - 20;
    charTab.selectGroup('Character');
    add(charTab);
    charTab.movable = false;
    charTab.cameras = [game.camHUD];

    // Character

    imageFile = new ALEInputText(50, 50);
    charTab.addObject('Character', createText(50, 30, 'Image:'));

    reloadImage = new ALEButton(320, 40, null, null, null, 'Reload');
    reloadImage.releaseCallback = () -> {
        if (Paths.fileExists('images/' + imageFile.value + '.png') && Paths.fileExists('images/' + imageFile.value + '.xml'))
            character.frames = Paths.getAtlas(imageFile.value);
    };

    voicesPostfix = new ALEInputText(50, 110);
    charTab.addObject('Character', createText(50, 90, 'Vocals Postfix:'));
    voicesPostfix.closeCallback = () -> {
        character.vocalsFile = voicesPostfix.value;
    };

    antialiasing = new ALECircleButton(290, 100, 'Antialiasing', 10);
    antialiasing.releaseCallback = () -> {
        character.antialiasing = antialiasing.value;
    };

    flipX = new ALECircleButton(290, 130, 'Flip X', 10);
    flipX.releaseCallback = () -> {
        character.originalFlipX = flipX.value;
        character.flipX = character.originalFlipX != character.isPlayer;
    };

    animationLength = new ALENumericStepper(50, 190, null, null, null, null, null, 4);
    charTab.addObject('Character', createText(50, 170, 'Animation Lenght:'));
    animationLength.callback = () -> {
        character.singDuration = animationLength.value;
    };

    scale = new ALENumericStepper(50, 250, null, null, null, null, 0.1, 1);
    charTab.addObject('Character', createText(50, 230, 'Scale:'));
    scale.callback = () -> {
        character.scale.x = character.scale.y = character.jsonScale = scale.value;
        character.updateHitbox();

        setCameraPosition();
    };

    charX = new ALENumericStepper(230, 190, null, null, -10000, 10000);
    charX.callback = () -> {
        setCharPosition([charX.value, null]);
    };

    charY = new ALENumericStepper(350, 190, null, null, -10000, 10000);
    charY.callback = () -> {
        setCharPosition([null, charY.value]);
    };

    charTab.addObject('Character', createText(230, 170, 'Position:'));

    camX = new ALENumericStepper(230, 250, null, null, -10000, 10000);
    camX.callback = () -> {
        setCameraPosition([camX.value, null]);
    }

    camY = new ALENumericStepper(350, 250, null, null, -10000, 10000);
    camY.callback = () -> {
        setCameraPosition([null, camY.value]);
    }

    charTab.addObject('Character', createText(230, 230, 'Camera Position:'));

    for (obj in [imageFile, reloadImage, voicesPostfix, antialiasing, flipX, animationLength, scale, charX, charY, camX, camY])
        charTab.addObject('Character', obj);

    // Animation

    animList = new ALEDropDown([], 50, 50, 200);
    animList.closeCallback = () -> {
        character.playAnim(animList.selected, true);

        resetAnimationUI();
    };
    charTab.addObject('Animation', createText(50, 30, 'Animation:'));

    animName = new ALEInputText(50, 110, 200);
    charTab.addObject('Animation', createText(50, 90, 'Name:'));

    animSymbol = new ALEInputText(50, 170, 200);
    charTab.addObject('Animation', createText(50, 150, 'Symbol Name / Name:'));

    animIndices = new ALEInputText(50, 230, 200);
    charTab.addObject('Animation', createText(50, 210, 'Indices:'));

    animFramerate = new ALENumericStepper(300, 50);
    charTab.addObject('Animation', createText(300, 30, 'Framerate:'));

    animLoop = new ALECircleButton(300, 110, 'Loop', 10);

    animUpdate = new ALEButton(300, 170, null, null, null, 'Add / Update');

    animDelete = new ALEButton(300, 230, null, null, null, 'Delete');

    for (obj in [animList, animName, animSymbol, animIndices, animFramerate, animLoop, animUpdate, animDelete])
        charTab.addObject('Animation', obj);

    // Icon

    iconName = new ALEInputText(50, 40, null, null, iconsList);
    charTab.addObject('Icon', createText(50, 20, 'Name:'));
    iconName.closeCallback = () -> {
        icon.changeIcon(iconName.value);
    };

    barColor = new ALEColorPicker(110, 90);
    barColor.callback = () -> {
        bar.rightBar.color = barColor.curColor;
    }

    loseIcon = new ALECircleButton(330, 40, 'Lose Icon', 10);
    
    for (obj in [iconName, barColor, loseIcon])
        charTab.addObject('Icon', obj);
}

function createMiscTab()
{
    miscTab = new ALEMultiTab(['Ghost', 'Settings', 'Save'], 0, 40, 400, 100);
    miscTab.x = FlxG.width - miscTab.width - 20;
    miscTab.selectGroup('Settings');
    add(miscTab);
    miscTab.movable = false;
    miscTab.cameras = [game.camHUD];

    // Settings

    charDrop = new ALEDropDown(charactersList, 50, 45);
    charDrop.closeCallback = () -> {
        if (character.curCharacter != charDrop.selected)
            loadCharacter(true);

        resetAnimationUI();
    };

    if (charactersList.contains('bf'))
    {
        charDrop.selected = 'bf';

        charDrop.selectedIndex = charactersList.indexOf('bf');
    }

    miscTab.addObject('Settings', createText(50, 20, 'Character:'));

    isPlayer = new ALECircleButton(230, 35, 'Player', 10);
    isPlayer.releaseCallback = () -> {
        character.isPlayer = isPlayer.value;

        setCharPosition();
    };

    for (obj in [charDrop, isPlayer])
        miscTab.addObject('Settings', obj);

    // Ghost

    addGhost = new ALEButton(50, 35, null, null, null, 'Make Ghost');
    addGhost.releaseCallback = () -> {
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
        ghost.alpha = 0.5;
        ghost.visible = true;
    };

    highlightGhost = new ALECircleButton(230, 35, 'Highlight', 10);
    highlightGhost.releaseCallback = () -> {
        ghost.colorTransform.redOffset = ghost.colorTransform.greenOffset = ghost.colorTransform.blueOffset = highlightGhost.value ? 100 : 0;
    }

    for (obj in [addGhost, highlightGhost])
        miscTab.addObject('Ghost', obj);

    // Save

    saveName = new ALEInputText(50, 45);
    miscTab.addObject('Save', createText(50, 25, 'File Name:'));

    saveButton = new ALEButton(225, 40, null, null, null, 'Save');
    saveButton.releaseCallback = () -> {
        var json = {
			animations: character.animationsArray,
			image: character.imageFile,
			scale: character.jsonScale,
			sing_duration: character.singDuration,
			healthicon: iconName.value,

			position: character.positionArray,
			camera_position: character.cameraPosition,

			flip_x: character.originalFlipX,
			no_antialiasing: character.noAntialiasing,
			healthbar_colors: [barColor.rStepper.value, barColor.gStepper.value, barColor.bStepper.value],
			vocals_file: character.vocalsFile,
			_editor_isPlayer: character.isPlayer
        };

        for (f in Reflect.fields(json))
            trace(f + ': ' + Reflect.field(json, f));

        trace('');

        for (anim in json.animations)
            for (f in Reflect.fields(anim))
                trace(f + ': ' + Reflect.field(anim, f));
    };
    
    for (obj in [saveName, saveButton])
        miscTab.addObject('Save', obj);
}


function readDirectories(searchFolder:String, extension:String):Array<String>
{
    var theList:Array<String> = [];

    for (folder in [Paths.modFolder() + '/' + searchFolder, 'assets/' + searchFolder])
        if (FileSystem.exists(folder) && FileSystem.isDirectory(folder))
            for (file in FileSystem.readDirectory(folder))
                if (file.toLowerCase().endsWith(extension.toLowerCase()) && !theList.contains(file.substring(0, file.length - 5)))
                    theList.push(file.substring(0, file.length - extension.length));

    return theList;
}

function createText(x:Float, y:Float, text:String):FlxText
{
    var txt:FlxText = new FlxText(x, y, 0, text, 15);
    txt.font = ALEUIUtils.font;

    return txt;
}

function resetUI()
{
    // Settings

    isPlayer.value = character.isPlayer;
    
    // Character

    charX.value = character.positionArray[0];
    charY.value = character.positionArray[1];

    camX.value = character.cameraPosition[0];
    camY.value = character.cameraPosition[1];

    imageFile.value = character.imageFile;
    imageFile.curIndex = imageFile.value.length;
    imageFile.setLinePos();

    voicesPostfix.value = character.vocalsFile;
    voicesPostfix.curIndex = voicesPostfix.value.length;
    voicesPostfix.setLinePos();

    animationLength.value = character.singDuration;

    scale.value = character.jsonScale;

    antialiasing.value = !character.noAntialiasing;

    flipX.value = character.originalFlipX;

    // Animation

    var animListStr = [for (anim in character.animationsArray) anim.anim];

    if (animListStr[0] != null)
        character.playAnim(animListStr[0], true);

    animList.options = animListStr;

    resetAnimationUI();

    // Icon

    iconName.value = character.healthIcon;
    iconName.curIndex = iconName.value.length;
    iconName.setLinePos();

    barColor.rStepper.value = character.healthColorArray[0];
    barColor.gStepper.value = character.healthColorArray[1];
    barColor.bStepper.value = character.healthColorArray[2];
    barColor.rgbColor();

    bar.rightBar.color = barColor.curColor;
}

function resetAnimationUI()
{
    var data = character.animationsArray[animList.selectedIndex];

    animName.value = data.anim;
    animName.curIndex = animName.value.length;
    animName.setLinePos();
    
    animSymbol.value = data.name;
    animSymbol.curIndex = animSymbol.value.length;
    animSymbol.setLinePos();
    
    animIndices.value = data.indices.join(', ');
    animIndices.curIndex = animSymbol.value.length;
    animIndices.setLinePos();

    animLoop.value = data.loop;

    animFramerate.value = data.fps;
}

function setCharPosition(?change:Array<Float>)
{
    if (change != null)
    {
        if (change[0] != null)
            character.positionArray[0] = change[0];

        if (change[1] != null)
            character.positionArray[1] = change[1];
    }

    character.x = (character.isPlayer ? BF_POSITION[0] : DAD_POSITION[0]) + character.positionArray[0];
    character.y = (character.isPlayer ? BF_POSITION[1] : DAD_POSITION[1]) + character.positionArray[1];

    setCameraPosition();
}

function setCameraPosition(?change:Array<Float>)
{
    if (change != null)
    {
        if (change[0] != null)
            character.cameraPosition[0] = change[0];

        if (change[1] != null)
            character.cameraPosition[1] = change[1];
    }

	var offX:Float = 0;
	var offY:Float = 0;

	if (!character.isPlayer)
	{
		offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
		offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
	} else {
		offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
		offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
	}

	followPointer.setPosition(offX, offY);

    FlxG.camera.scroll.x = followPointer.getMidpoint().x - FlxG.width / 2;
    FlxG.camera.scroll.y = followPointer.getMidpoint().y - FlxG.height / 2;
}