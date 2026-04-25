package;

import ale.ui.*;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxStringUtil;

import utils.Formatter;

import EditorUtil;

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

    initUI();
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

        curOffset += grid.grid.width + EditorUtil.NOTE_SIZE;
    }

    cameraData.offset.x = -FlxG.width / 2 + (curOffset - EditorUtil.NOTE_SIZE) / 2;
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

    updateUI(elapsed);
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
    if (music.time < 0.1)
        music.time = 0.1;

    if (music.time > music.length)
        music.time = music.length;

    Conductor.songPosition = music.time;
}

function updateCamera()
{
    camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, cameraData.zoom, 0.25);

    songLine.scale.x = songLine.scale.y = 1 / camGame.zoom;

    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, cameraData.offset.x, 0.25);
    camGame.scroll.y = (Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time) % Conductor.sectionCrochet / Conductor.stepCrochet * EditorUtil.NOTE_SIZE + cameraData.offset.y;

    songLine.y = -cameraData.offset.y;
}


var uiGroup:FlxTypedGroup<FlxSprite>;

var conductorTab:Tab;
var conductorTabText:FlxText;

function initUI()
{
    uiGroup = new FlxTypedGroup<FlxSprite>();
    add(uiGroup);

    conductorTabText = new FlxText(10, 10, 0, [for (i in 0...6) ' '].join('\n'), 15);
    conductorTabText.font = UIUtils.FONT;

    conductorTab = new Tab(0, 0, 170, conductorTabText.height + 20, 'Conductor');
    EditorUtil.setToMargin(conductorTab, true, true);
    uiGroup.add(conductorTab);

    conductorTab.add(conductorTabText);

    for (obj in uiGroup)
        obj.cameras = [camHUD];
}

function updateUI(elapsed:Float)
{
    conductorTabText.text = [
        'Time: ' + FlxStringUtil.formatTime(Math.floor(Conductor.songPosition) / 1000, true),
        'BPM: ' + Conductor.bpm,
        'Step: ' + Conductor.curStep,
        'Beat: ' + Conductor.curBeat,
        'Section: ' + Conductor.curSection,
        'Signature: ' + Conductor.beatsPerSection + ' | ' + Conductor.stepsPerBeat
    ].join('\n');
}