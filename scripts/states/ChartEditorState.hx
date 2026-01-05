import lime.app.Application;

import utils.cool.PlayStateUtil;
import utils.ALEFormatter;

import funkin.visuals.editors.ChartGrid;

import ale.ui.*;

import flixel.math.FlxPoint;
import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;

final NOTE_SIZE:Int = 50;

final SONG:String = 'Satin-Panties';

final LINE_POS:Int = 200;

final CHARACTERS_MAP:StringMap<String> = new StringMap();

for (char in [for (char in Paths.readDirectory('characters', 'multiple')) char.substr(0, char.length - 5)])
    CHARACTERS_MAP.set(char, ALEFormatter.getCharacter(char).healthicon);

var bg:FlxSprite;

var music(get, never):FlxSound;
function get_music(val:String)
    return FlxG.sound.music;

var grids:FlxTypedGroup<ChartGrid>;

var conductorInfo:FlxText;

function postCreate()
{
    shouldUpdateMusic = false;

    Conductor.songPosition = 0;

    FlxG.sound.playMusic(Paths.inst('songs/' + SONG));

    music.pause();

    bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.BLACK, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)]);
    bg.scrollFactor.set();

    add(bg);

    PlayState.SONG = PlayStateUtil.loadPlayStateSong(SONG, 'hard').json;

    calculateBPMChanges(PlayState.SONG);

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (i in 0...2)
        addGrid();

    var button = new ale.ui.ALEButton(100, 100, 'Create Grid');
    button.releaseCallback = addGrid;
    button.cameras = [camHUD];
    add(button);

    conductorInfo = new FlxText(10, 10, 0, 'Time\nStep\nBeat\nSection\nBPM', 15);
    conductorInfo.font = ALEUIUtils.FONT;

    var conductorTab:ALETab = new ALETab(0, 0, 200, conductorInfo.height + 20, 'Conductor');
    add(conductorTab);
    conductorTab.cameras = [camHUD];
    
    conductorInfo.fieldWidth = conductorTab.width - 20;
    conductorTab.add(conductorInfo);

    conductorTab.x = FlxG.width - conductorTab.width - 40;
    conductorTab.y = FlxG.height - conductorTab.height - 20;
}

final GRID_SPACE:Int = 25;

var gridOffset:Float = 0;

var camData:{pos:Float, zoom:Float} = {
    pos: 0,
    zoom: 1
};

var chart:ALEChart = {
    strumLines: [],
    sections: [],
    format: 'ale-psych-0.1-format'
};

function addGrid(?config:String)
{
    var newGrid:ChartGrid = new ChartGrid(CHARACTERS_MAP, NOTE_SIZE, LINE_POS, config ?? 'default');

    FlxTween.tween(newGrid, {x: gridOffset}, 0.5, {ease: FlxEase.cubeOut});

    gridOffset += newGrid.background.width + GRID_SPACE;

    camData.pos = Math.max(0, gridOffset - GRID_SPACE) / 2 - FlxG.width / 2;

    grids.add(newGrid);
}

var _lastTime:Float = -1;

function onUpdate(elapsed:Float)
{
    updateMusicControls();

    updateCamera();

    if (Conductor.songPosition != _lastTime)
    {
        _lastTime = Conductor.songPosition;

        conductorInfo.text = 'Time: ' + FlxStringUtil.formatTime(_lastTime / 1000, true) + '\n- Step: ' + Conductor.curStep + '\n- Beat: ' + Conductor.curBeat + '\n- Section: ' + Conductor.curSection + '\nBPM: ' + Conductor.bpm;
    }
}

var musicY(get, never):Float;
function get_musicY():Float
{
    return (Conductor.songPosition - bpmChangeMap[curBPMIndex].time) % Conductor.sectionCrochet / Conductor.stepCrochet * NOTE_SIZE;
}

var MUSIC_CHANGE(get, never):Float;
function get_MUSIC_CHANGE():Float
{
    return 30 * (FlxG.keys.pressed.SHIFT ? 2 : 1);
}

var CURRENT_SECTION(get, never):SwagSection;
function get_CURRENT_SECTION():SwagSection
{
    return PlayState.SONG.notes[Conductor.curSection];
}

var _lastSec:Int = -1;

function updateMusicControls()
{
    if (Controls.UI_LEFT_P || Controls.UI_RIGHT_P || Controls.UI_UP || Controls.UI_DOWN || ((!Controls.SHIFT && !Conductor.CONTROL) && Controls.MOUSE_WHEEL))
    {
        if (Controls.UI_UP || Controls.UI_DOWN)
            music.time += MUSIC_CHANGE * (Controls.UI_UP ? -1 : 1);

        if (Controls.MOUSE_WHEEL)
            music.time += Conductor.stepCrochet * (Controls.MOUSE_WHEEL_DOWN ? 1 : -1);

        if (Controls.UI_LEFT_P || Controls.UI_RIGHT_P)
            music.time += Conductor.sectionCrochet * (Controls.UI_LEFT_P ? -1 : 1) * (Controls.SHIFT ? 4 : 1);

        music.time = FlxMath.bound(music.time, 0, music.length);

        if (music.playing)
            music.pause();
    } else if (FlxG.keys.justPressed.SPACE) {
        if (music.playing)
            music.pause();
        else
            music.resume();
    }

    Conductor.songPosition = music.time;
    
    camGame.scroll.y = -LINE_POS + musicY;

    shouldUpdateMusic = true;

    updateMusic();

    shouldUpdateMusic = false;
}

function updateCamera()
{
    if (Controls.MOUSE_WHEEL)
        if (Controls.SHIFT)
            camData.pos -= FlxG.mouse.wheel * 50;
        else if (Controls.CONTROL)
            camData.zoom = FlxMath.bound(camData.zoom + FlxG.mouse.wheel * camData.zoom * 0.1, 0.25, 2);

    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, camData.pos, 0.25);
    camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, camData.zoom, 0.25);

    bg.scale.x = bg.scale.y = CoolUtil.fpsLerp(bg.scale.x, 1 / camData.zoom, 0.25);
}

// ----------- ADRIANA SALTE -----------

function onHotReloadingConfig()
{
    for (file in ['ChartNote', 'ChartGrid'])
        addHotReloadingFile('scripts/classes/funkin/visuals/editors/' + file + '.hx');
}

if (false)
{
    final window:Window = Application.current.window;

    final screenSize:FlxPoint = FlxPoint.get(1920, 1080);

    window.width = screenSize.x / 2 * 0.9;
    window.height = screenSize.y / 2 * 0.9;
    window.x = screenSize.x / 4 - window.width / 2;
    window.y = screenSize.y / 4 - window.height / 2 + 40;
}