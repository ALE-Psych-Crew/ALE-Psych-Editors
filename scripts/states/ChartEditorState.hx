import lime.app.Application;

import utils.cool.PlayStateUtil;

import funkin.visuals.editors.ChartGrid;

import ale.ui.ALEUIUtils;

import flixel.math.FlxPoint;
import flixel.util.FlxGradient;

final NOTE_SIZE:Int = 50;

var BEATS_PER_SECTION:Int = 4;
var STEPS_PER_BEAT:Int = 4;

final LINE_POS:Int = 200;

var bg:FlxSprite;

var grids:FlxTypedGroup<ChartGrid>;

var music(get, never):FlxSound;
function get_music(val:String)
    return FlxG.sound.music;

var lastBPM(default, set):Float;
function set_lastBPM(val:Float):Float
{
    lastBPM = val;

    Conductor.bpm = lastBPM;

    return lastBPM;
}

function postCreate()
{
    Conductor.songPosition = 0;

    FlxG.sound.playMusic(Paths.inst('songs/monster'));

    music.pause();

    music.time = 80000;

    bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.BLACK, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)]);
    bg.scrollFactor.set();

    add(bg);

    PlayState.SONG = PlayStateUtil.loadPlayStateSong('monster', 'hard').json;

    calculateBPMChanges(PlayState.SONG);

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (i in 0...2)
        addGrid();

    var button = new ale.ui.ALEButton(100, 100, 'Create Grid');
    button.releaseCallback = addGrid;
    button.cameras = [camHUD];
    add(button);
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
    var newGrid:ChartGrid = new ChartGrid(NOTE_SIZE, BEATS_PER_SECTION, STEPS_PER_BEAT, LINE_POS, config ?? 'default');

    FlxTween.tween(newGrid, {x: gridOffset}, 0.5, {ease: FlxEase.cubeOut});

    gridOffset += newGrid.background.width + GRID_SPACE;

    camData.pos = Math.max(0, gridOffset - GRID_SPACE) / 2 - FlxG.width / 2;

    grids.add(newGrid);
}

function onUpdate(elapsed:Float)
{
    updateMusic();

    updateCamera();
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

function updateMusic()
{
    if (Controls.UI_UP || Controls.UI_DOWN || ((!Controls.SHIFT && !Conductor.CONTROL) && Controls.MOUSE_WHEEL))
    {
        if (Controls.UI_UP || Controls.UI_DOWN)
            music.time = FlxMath.bound(music.time + MUSIC_CHANGE * (Controls.UI_UP ? -1 : 1), 0, music.length);

        if (!Controls.SHIFT && !Controls.CONTROL)
            if (Controls.MOUSE_WHEEL)
                music.time = Math.floor(FlxMath.bound(music.time + Conductor.stepCrochet * (Controls.MOUSE_WHEEL_UP ? -1 : 1), 0, music.length) / Conductor.stepCrochet) * Conductor.stepCrochet;

        if (music.playing)
            music.pause();
    } else if (FlxG.keys.justPressed.SPACE) {
        if (music.playing)
            music.pause();
        else
            music.resume();
    }
    
    camGame.scroll.y = -LINE_POS + musicY;

    Conductor.songPosition = music.time;
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
    debugTrace('Init State');

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
