package;

import flixel.input.keyboard.FlxKey;

import utils.Formatter;

import Constants;

var music(get, never):FlxSound;
function get_music():FlxSound
    return FlxG.sound.music;

final CHART:ALESong;

final songRoute:String;

function new(?song:String = 'bopeebo', ?diff:String = 'hard', ?chart:ALESong)
{
    CHART = chart ?? Formatter.getSong(song, diff);

    Conductor.calculateBPMChanges(CHART);

    songRoute = CoolUtil.searchComplexFile('songs/' + song);

    FlxG.sound.playMusic(Paths.inst(songRoute));

    music.pause();
}

final cameraData = {
    zoom: 1,
    offset: {
        x: 0,
        y: -200
    }
};

var grids:FlxTypedGroup<ChartGrid>;

var songLine:FlxSprite;

function onCreate()
{
    Conductor.bpm = CHART.sections[0] != null && CHART.sections[0].bpm && CHART.sections[0].changeBPM ? CHART.sections[0].bpm : CHART.bpm;

    Conductor.beatsPerSection = CHART.beatsPerSection;
    Conductor.stepsPerBeat = CHART.stepsPerBeat;

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (strl in CHART.strumLines)
        createGrid(strl);

    songLine = new FlxSprite(0, -1).makeGraphic(FlxG.width, 2);
    songLine.scrollFactor.set();
    songLine.alpha = 0.5;
    add(songLine);

    camGame.scroll.x = cameraData.offset.x;
    camGame.scroll.y = cameraData.offset.y;
}

function createGrid(data:ALESongStrumLine)
{
    grids.add(new ChartGrid(data));

    var curOffset:Int = 0;

    for (index => grid in grids)
    {
        FlxTween.cancelTweensOf(grid);

        if (true)
            grid.x = curOffset;
        else
            FlxTween.tween(grid, {x: curOffset}, 0.5, {ease: FlxEase.cubeOut});

        if (index == grids.members.length - 1)
            cameraData.offset.x = -curOffset / 2;

        curOffset += grid.grid.width + Constants.NOTE_SIZE;
    }
}

function justPressedKey(key:FlxKey)
    return Controls.anyJustPressed([key]);

function pressedKey(key:FlxKey)
    return Controls.anyPressed([key]);

function onUpdate(elapsed:Float)
{
    updateControls(elapsed);

    updateMusic();

    updateCamera();
}

var musicChange(get, never):Float;
function get_musicChange():Float
    return Controls.SHIFT ? 6000 : 3000;

function updateControls(elapsed:Float)
{
    if (justPressedKey(FlxKey.SPACE))
    {
        if (music.playing)
            music.pause();
        else
            music.play();
    }

    if (Controls.anyPressed([FlxKey.S, FlxKey.W]))
    {
        music.pause();

        music.time += musicChange * (pressedKey(FlxKey.W) ? -1 : 1) * elapsed;
    }
    
    if (Controls.MOUSE_WHEEL)
    {
        if (Controls.CONTROL)
        {
            cameraData.zoom += FlxG.mouse.wheel * 0.1 * camGame.zoom;
        } else if (Controls.SHIFT) {
            cameraData.offset.x -= FlxG.mouse.wheel * 100 / camGame.zoom;
        } else {
            music.pause();

            music.time += Conductor.stepCrochet * -FlxG.mouse.wheel;
        }
    }

    if (Controls.anyJustPressed([FlxKey.A, FlxKey.D]))
    {
        music.pause();

        music.time += Conductor.sectionCrochet * (justPressedKey(FlxKey.A) ? -1 : 1);
    }
}

function updateMusic()
{
    if (music.time < 0)
        music.time = 0;

    if (music.time > music.length)
        music.time = music.length;

    Conductor.songPosition = music.time;
}

function updateCamera()
{
    camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, cameraData.zoom, 0.25);

    songLine.scale.x = songLine.scale.y = 1 / camGame.zoom;

    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, cameraData.offset.x, 0.25);
    camGame.scroll.y = (Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time) % Conductor.sectionCrochet / Conductor.stepCrochet * Constants.NOTE_SIZE + cameraData.offset.y;

    songLine.y = -cameraData.offset.y;
}