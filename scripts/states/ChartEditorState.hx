import flixel.util.FlxGradient;

import funkin.visuals.editors.ChartGrid;

import funkin.visuals.FXCamera;

// import core.structures.ALESong;

import utils.ALEFormatter;

import ale.ui.ALEUIUtils;

using StringTools;

// ------- ADRIANA SALTE ------- //

function onHotReloadingConfig()
{
    for (pack in ['utils', 'funkin.visuals.editors'])
        for (file in Paths.readDirectory('scripts/classes/' + pack.replace('.', '/')))
            addHotReloadingFile('scripts/classes/' + pack.replace('.', '/') + '/' + file);
}

if (false)
{
    final window:Window = lime.app.Application.current.window;

    final screenSize:FlxPoint = flixel.math.FlxPoint.get(1920, 1080);

    window.width = screenSize.x / 2 * 0.9;
    window.height = screenSize.y / 2 * 0.9;
    window.x = screenSize.x / 4 - window.width / 2;
    window.y = screenSize.y / 4 - window.height / 2 + 40;
}

// ------- ADRIANA SALTE ------- //

final NOTE_SIZE:Int = 50;

var CHART:ALESong;
var song:String;

var bg:FlxSprite;

var grids:FlxTypedGroup<ChartGrid>;

public function new(?data:ALESong, ?songName:String)
{
    songName ??= 'bopeebo';

    song = songName;

    data ??= ALEFormatter.getSong(song, 'hard');

    CHART = data;

    Conductor.reset(CHART.bpm, CHART.stepsPerBeat, CHART.beatsPerSection);
    
    Conductor.calculateBPMChanges(CHART);
}

var music(get, never):FlxSound;
function get_music():FlxSound
    return FlxG.sound.music;

var gridMap:Array<Array<ChartGrid>> = [];

function onCreate()
{
    FlxG.sound.playMusic(Paths.inst('songs/' + song));

    music.pause();

    bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.BLACK, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)]);
    add(bg);
    bg.scrollFactor.set();

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (index => strl in CHART.strumLines)
    {
        gridMap[index] ??= [];

        for (char in strl.characters)
        {
            final grid:ChartGrid = addGrid(strl.file);
            
            gridMap[index].push(grid);
        }
    }

    for (index => section in CHART.sections)
    {
        for (note in section.notes)
        {
            var gridSections = gridMap[note[4][0]][note[4][1]].sections;

            gridSections[index] ??= [];

            gridSections[index].push(
                {
                    time: note[0],
                    data: note[1],
                    length: note[2],
                    type: note[3]
                }
            );
        }
    }

    for (grid in grids)
        grid.updateSection(Conductor.curSection);
}

var camPos = {x: 0, zoom: 1, offset: 300};

var gridOffset:Int = 0;

function addGrid(id:String):ChartGrid
{
    final grid:ChartGrid = new ChartGrid(id, NOTE_SIZE);
    grids.add(grid);

    FlxTween.tween(grid, {x: gridOffset}, 0.3, {ease: FlxEase.cubeOut});

    gridOffset += grid.bg.width + NOTE_SIZE;

    camPos.x = -FlxG.width / 2 + (gridOffset - NOTE_SIZE) / 2;

    return grid;
}

function onUpdate(elapsed:Float)
{
    if (music != null)
        updateMusic(elapsed);

    updateCamera(elapsed);

    Conductor.songPosition = music == null ? 0 : music.time;

    bg.scale.x = bg.scale.y = 1 / camGame.zoom;
}

var musicChange(get, never):Float;
function get_musicChange():Float
    return Controls.SHIFT ? 6000 : 3000;

function updateMusic(elapsed:Float)
{
    if (FlxG.keys.justPressed.SPACE)
        if (music.playing)
            music.pause();
        else
            music.play();
        
    if (Controls.UI_UP || Controls.UI_DOWN || Controls.MOUSE_WHEEL || Controls.UI_LEFT_P || Controls.UI_RIGHT_P)
    {
        final musicChange:Float = (Controls.SHIFT ? 6000 : 3000) * elapsed;

        if (Controls.UI_UP)
            music.time -= musicChange;
        
        if (Controls.UI_DOWN)
            music.time += musicChange;

        if (Controls.MOUSE_WHEEL)
            music.time -= FlxG.mouse.wheel * Conductor.stepCrochet;

        if (Controls.UI_LEFT_P || Controls.UI_RIGHT_P)
            music.time += (Controls.UI_LEFT_P ? -1 : 1) * Conductor.sectionCrochet;

        music.time = FlxMath.bound(music.time, 1, music.length);

        if (music.playing)
            music.pause();
    }
}

function updateCamera(elapsed:Float)
{
    if (Controls.MOUSE_WHEEL)
    {
        if (Controls.SHIFT)
        {
            camPos.x -= FlxG.mouse.wheel * 1000 * elapsed;
        } else if (Controls.CONTROL) {
            camPos.zoom += FlxG.mouse.wheel * elapsed * 10 * camGame.zoom;

            camPos.zoom = FlxMath.bound(camPos.zoom, 0.1, 3);
        }
    }

    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, camPos.x, 0.3);
    camGame.scroll.y = (Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time) % Conductor.sectionCrochet / Conductor.stepCrochet * NOTE_SIZE - camPos.offset;

    camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, camPos.zoom, 0.3);
}