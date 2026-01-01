import lime.app.Application;

import utils.cool.PlayStateUtil;

import funkin.visuals.editors.ChartGrid;

import ale.ui.ALEUIUtils;

import flixel.math.FlxPoint;
import flixel.util.FlxGradient;

final NOTE_SIZE:Int = 50;

final STEPS:Int = 16;

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
    FlxG.sound.playMusic(Paths.voices('songs/stress'));

    music.pause();

    music.time = 0;

    bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.BLACK, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)]);
    bg.scrollFactor.set();

    add(bg);

    PlayState.SONG = PlayStateUtil.loadPlayStateSong('stress', 'hard').json;

    Conductor.mapBPMChanges(PlayState.SONG);
    Conductor.bpm = PlayState.SONG.bpm ?? 100;

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (i in 0...2)
        addGrid();

    addGrid([
        {
            animation: 'A0',
            shader: [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56]
        },
        {
            animation: 'B0',
            shader: [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7]
        },
        {
            animation: 'C0',
            shader: [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447]
        },
        {
            animation: 'D0',
            shader: [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
        },
        {
            animation: 'E0',
            shader: [0xFF999999, 0xFFFFFFFF, 0xFF201E31]
        },
        {
            animation: 'F0',
            shader: [0xFFFFFF00, 0xFFFFFFFF, 0xFF993300]
        },
        {
            animation: 'G0',
            shader: [0xFF8b4aff, 0xFFFFFFFF, 0xFF3b177d]
        },
        {
            animation: 'H0',
            shader: [0xFFFF0000, 0xFFFFFFFF, 0xFF660000]
        },
        {
            animation: 'I0',
            shader: [0xFF0033ff, 0xFFFFFFFF, 0xFF000066]
        }
    ], ['NOTE_multi']);

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
    sections: []
};

function addGrid(?config:Array<ChartStrumConfig>, ?sprites:Array<String>)
{
    var newGrid:ChartGrid = new ChartGrid(NOTE_SIZE, STEPS * 2, LINE_POS, config, sprites);

    FlxTween.tween(newGrid, {x: gridOffset}, 0.5, {ease: FlxEase.cubeOut});

    gridOffset += newGrid.background.width + GRID_SPACE;

    camData.pos = Math.max(0, gridOffset - GRID_SPACE) / 2 - FlxG.width / 2;

    grids.add(newGrid);
}

function onUpdate(elapsed:Float)
{
    updateMusic();

    updateCamera();

    if (Controls.ACCEPT)
        saveChart();
}

var musicY(get, never):Float;
function get_musicY():Float
{
    return (Conductor.songPosition / Conductor.stepCrochet * NOTE_SIZE) % (NOTE_SIZE * STEPS);
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

function updateMusic()
{
    /*
    if (CURRENT_SECTION.changeBPM != null)
        if (CURRENT_SECTION.changeBPM)
            if (CURRENT_SECTION.bpm != lastBPM)
                lastBPM = CURRENT_SECTION.bpm;
    */

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

function saveChart()
{
    chart.strumLines = [];

    for (gridIndex => grid in grids)
    {
        chart.strumLines.push({
            strums: grid.strums,
            sprites: grid.textures
        });

        for (sectionIndex => section in grid.sections)
        {
            chart.sections[sectionIndex] ??= {
                notes: []
            };

            chart.sections[sectionIndex].notes = [];

            for (note in section)
            {
                if (note == null)
                    continue;

                chart.sections[sectionIndex].notes.push([
                    note.time,
                    note.data,
                    note.length,
                    note.type,
                    gridIndex
                ]);
            }
        }
    }

    File.saveContent('OSO_CHART.json', Json.stringify(chart));
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