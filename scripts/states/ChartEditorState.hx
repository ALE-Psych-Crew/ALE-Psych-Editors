import lime.app.Application;

import utils.cool.PlayStateUtil;

import funkin.visuals.editors.ChartGrid;

import flixel.math.FlxPoint;

final NOTE_SIZE:Int = 50;

final STEPS:Int = 16;

final LINE_POS:Int = 300;

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

    PlayState.SONG = PlayStateUtil.loadPlayStateSong('stress', 'hard').json;

    Conductor.mapBPMChanges(PlayState.SONG);
    Conductor.bpm = PlayState.SONG.bpm ?? 100;

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    grids.add(new ChartGrid(NOTE_SIZE, 4, STEPS * 2, LINE_POS));
}

function onUpdate(elapsed:Float)
{
    updateMusic();
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

    if (FlxG.keys.justPressed.SPACE)
        if (music.playing)
            music.pause();
        else
            music.resume();

    if (Controls.UI_UP_P || Controls.UI_DOWN_P || Controls.MOUSE_WHEEL)
        if (music.playing)
            music.pause();

    if (Controls.UI_UP || Controls.UI_DOWN)
        music.time = FlxMath.bound(music.time + MUSIC_CHANGE * (Controls.UI_UP ? -1 : 1), 0, music.length);
    
    if (Controls.MOUSE_WHEEL)
        music.time = Math.floor(FlxMath.bound(music.time + Conductor.stepCrochet * (Controls.MOUSE_WHEEL_UP ? -1 : 1), 0, music.length) / Conductor.stepCrochet) * Conductor.stepCrochet;

    camGame.scroll.y = -LINE_POS + musicY;
}

function onHotReloadingConfig()
{
    debugTrace('Init State');

    for (file in ['ChartNote', 'ChartGrid'])
        addHotReloadingFile('scripts/classes/funkin/visuals/editors/' + file + '.hx');
}

if (true)
{
    final window:Window = Application.current.window;

    final screenSize:FlxPoint = FlxPoint.get(1920, 1080);

    window.width = screenSize.x / 2 * 0.9;
    window.height = screenSize.y / 2 * 0.9;
    window.x = screenSize.x / 4 - window.width / 2;
    window.y = screenSize.y / 4 - window.height / 2 + 40;
}