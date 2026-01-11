import haxe.ds.StringMap;

import lime.app.Application;

import utils.cool.PlayStateUtil;
import utils.ALEFormatter;

import funkin.visuals.editors.ChartGrid;

import ale.ui.*;

import flixel.math.FlxPoint;
import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;

using StringTools;

function calculateBPMChanges(?song:Null<ALESong>)
{
    if (song == null)
    {
        bpmChangeMap = null;

        return;
    }

    var curTime:Float = 0;
    var curStep:Int = 0;

    Conductor.bpm = song.bpm;
    
    bpmChangeMap = [
        {
            bpm: Conductor.bpm,
            time: 0,
            step: 0
        }
    ];

    for (section in song.sections)
    {
        if (section.changeBPM && section.bpm != Conductor.bpm)
        {
            Conductor.bpm = section.bpm;

            bpmChangeMap.push(
                {
                    bpm: Conductor.bpm,
                    time: curTime,
                    step: curStep
                }
            );
        }
        
        curTime += Conductor.sectionCrochet;
        curStep += Conductor.beatsPerSection * Conductor.stepsPerBeat;
    }

    Conductor.bpm = song.bpm;
}

final NOTE_SIZE:Int = 50;

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

var loadedSong:ALESong;

var sections:Array<ChartSection> = [];

final song:String;
final difficulty:String;

function new(?mySong:String, ?myDifficulty:String)
{
    song = mySong ?? 'monster';

    difficulty = myDifficulty ?? 'normal';

    FlxG.sound.playMusic(Paths.voices('songs/' + song));

    music.pause();

    loadedSong = ALEFormatter.getSong(song, difficulty);
}

var gridMap:Array<Array<ChartGrid>> = [];

function postCreate()
{
    Conductor.songPosition = 0;

    bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.BLACK, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)]);
    bg.scrollFactor.set();

    add(bg);

    Conductor.stepsPerBeat = loadedSong.stepsPerBeat;
    Conductor.beatsPerSection = loadedSong.beatsPerSection;

    calculateBPMChanges(loadedSong);

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (index => strl in loadedSong.strumLines)
    {
        gridMap[index] ??= [];

        for (charIndex => character in strl.characters)
        {
            final grid:ChartGrid = addGrid(strl.file);
            grid.charIndex = charIndex;
            grid.configID = strl.file + '::' + index;
            grid.setCharacter(character);

            gridMap[index].push(grid);
        }
    }

    var timedNotes:Array<Array<Float>> = [for (i in 0...loadedSong.sections.length) []];

    var noteIndex:Int = -1;

    var noteTime:Float = 0;

    var noteSection:Int = 0;

    for (sectionIndex => section in loadedSong.sections)
    {
        sections[sectionIndex] = {
            camera: section.camera,
            bpm: section.bpm,
            changeBPM: section.changeBPM
        };
        
        for (note in section.notes)
        {
            while (noteIndex < bpmChangeMap.length - 1 && note[0] > bpmChangeMap[noteIndex + 1].time)
            {
                noteIndex++;

                Conductor.bpm = bpmChangeMap[noteIndex].bpm;

                noteTime = bpmChangeMap[noteIndex].time;
            }

            while (note[0] >= noteTime + Conductor.sectionCrochet)
            {
                noteTime += Conductor.sectionCrochet;

                noteSection++;
            }

            timedNotes[noteSection] ??= [];

            timedNotes[noteSection].push(note);
        }
    }

    Conductor.bpm = loadedSong.bpm;

    for (sectionIndex => section in timedNotes)
    {
        for (note in section)
        {
            gridMap[note[4][0]][note[4][1]].sections[sectionIndex] ??= [];

            gridMap[note[4][0]][note[4][1]].sections[sectionIndex].push(
                {
                    time: note[0],
                    data: note[1],
                    length: note[2],
                    type: note[3]
                }
            );
        }
    }

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

var chart:ALESong = {
    strumLines: [],
    sections: [],
    format: 'ale-psych-0.1-format'
};

function addGrid(?config:String):ChartGrid
{
    var newGrid:ChartGrid = new ChartGrid(CHARACTERS_MAP, NOTE_SIZE, LINE_POS, config ?? 'default');

    FlxTween.tween(newGrid, {x: gridOffset}, 0.5, {ease: FlxEase.cubeOut});

    gridOffset += newGrid.background.width + GRID_SPACE;

    camData.pos = Math.max(0, gridOffset - GRID_SPACE) / 2 - FlxG.width / 2;

    grids.add(newGrid);

    return newGrid;
}

function onUpdate(elapsed:Float)
{
    updateMusicControls();

    updateCamera();
    
    updateShortcuts();

    setTarget();
}

function updateShortcuts()
{
    if (Controls.CONTROL)
    {
        if (FlxG.keys.justPressed.S)
        {
            saveChart();
        }
    }
}

function setTarget()
{
    
}

var musicY(get, never):Float;
function get_musicY():Float
{
    return (Conductor.songPosition - bpmChangeMap[curBPMIndex].time) % Conductor.sectionCrochet / Conductor.stepCrochet * NOTE_SIZE;
}

var updateTime:Float = -1;

function postUpdate(elapsed:Float)
{
    if (updateTime != Conductor.songPosition)
    {
        updateTime = Conductor.songPosition;

        conductorInfo.text = 'Time: ' + FlxStringUtil.formatTime(Conductor.songPosition / 1000, true) + '\n- Step: ' + Conductor.curStep + '\n- Beat: ' + Conductor.curBeat + '\n- Section: ' + Conductor.curSection + '\nBPM: ' + Conductor.bpm;

        camGame.scroll.y = -LINE_POS + musicY;
    }
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

function updateMusicControls()
{
    if ((Controls.UI_LEFT_P || Controls.UI_RIGHT_P || Controls.UI_UP || Controls.UI_DOWN || Controls.MOUSE_WHEEL) && !(Controls.SHIFT && Conductor.MOUSE_WHEEL) && !Controls.CONTROL)
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
    final strlIndexMap:StringMap<Int> = new StringMap<Int>();

    final chart:ALESong = {
        strumLines: [],
        sections: [],
        beatsPerSection: loadedSong.beatsPerSection,
        stepsPerBeat: loadedSong.stepsPerBeat,
        format: ALEFormatter.FORMAT,
        bpm: loadedSong.bpm
    };

    for (index => section in sections)
    {
        chart.sections[index] = {
            notes: [],
            camera: section.camera,
            bpm: section.bpm,
            changeBPM: section.changeBPM
        };
    }

    for (grid in grids)
    {
        if (grid != null)
        {
            if (strlIndexMap.exists(grid.configID))
            {
                chart.strumLines[strlIndexMap.get(grid.configID)].characters[grid.charIndex] = grid.character;
            } else {
                strlIndexMap.set(grid.configID, chart.strumLines.length);

                chart.strumLines.push(
                    {
                        file: grid.configID.split('::')[0],
                        position: grid.position,
                        rightToLeft: grid.rightToLeft,
                        visible: grid.visibleStrumline,
                        characters: [grid.character]
                    }
                );
            }

            for (index => section in grid.sections)
            {
                if (section == null)
                    continue;

                chart.sections[index] ??= {
                    notes: [],
                    camera: [0, 0],
                    bpm: loadedSong.bpm,
                    changeBPM: false
                };

                for (note in section)
                {
                    if (note == null)
                        continue;

                    chart.sections[index].notes.push([
                        note.time,
                        note.data,
                        note.length,
                        note.type,
                        [strlIndexMap.get(grid.configID), grid.charIndex]
                    ]);
                }
            }
        }
    }

    File.saveContent(difficulty + '.json', Json.stringify(chart));
}

// ----------- ADRIANA SALTE -----------

function onHotReloadingConfig()
{
    for (file in ['funkin.visuals.editors.ChartNote', 'funkin.visuals.editors.ChartGrid', 'utils.ALEFormatter'])
        addHotReloadingFile('scripts/classes/' + file.replace('.', '/') + '.hx');
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