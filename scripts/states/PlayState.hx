import lime.app.Application;

import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.FlxObject;

import utils.ALEFormatter;

import funkin.visuals.game.StrumLine;
import funkin.visuals.game.Character;

//import core.structures.ALESong;
//import core.structures.ALESongSection;

using StringTools;

var SONG:ALESong;

var STAGE:ALEStage;

var instSound:openfl.media.Sound;

function new(?song:String, ?difficulty:String)
{
    SONG ??= ALEFormatter.getSong(song ?? 'bopeebo', difficulty ?? 'hard');

    STAGE ??= ALEFormatter.getStage(SONG.stage);

    instSound = Paths.voices('songs/' + (song ?? 'bopeebo'));
}

function postCreate()
{
    ClientPrefs.data.downScroll = true;
    ClientPrefs.data.botplay = false;

    ClientPrefs.data.framerate = 1000;

    loadSong();

    initControls();

    initCamera();
    
    FlxG.sound.playMusic(instSound);
}

var characters:FlxTypedGroup<Character>;

var strumLines:FlxTypedGroup<StrumLine>;

var cameraCharacters:Array<Array<Character>> = [];

function initStrumLines()
{
    final notes:Array<Array<Dynamic>> = [];

    Conductor.bpm = SONG.bpm;

    for (section in SONG.sections)
    {
        if (section.changeBPM)
            Conductor.bpm = section.bpm;

        for (note in section.notes)
        {
            notes[note[4][0]] ??= [];

            notes[note[4][0]].push(
                [
                    note[0],
                    note[1],
                    note[2],
                    note[3],
                    note[4][1],
                    Conductor.stepCrochet
                ]
            );
        }
    }

    Conductor.bpm = SONG.bpm;

    add(characters = new FlxTypedGroup<Character>());

    add(strumLines = new FlxTypedGroup<StrumLine>());
    strumLines.cameras = [camHUD];

    for (strlIndex => strl in SONG.strumLines)
    {
        final strlCharacters:Array<Character> = [];

        for (character in strl.characters)
        {
            final character:Character = new Character(character, strl.type);

            character.x = character.data.position.x;
            character.y = character.data.position.y;

            if (STAGE.characterOffset != null && STAGE.characterOffset.type != null)
            {
                final offset = Reflect.getProperty(STAGE.characterOffset.type, cast character.type);

                if (offset != null)
                {
                    character.x += offset.x;
                    character.y += offset.y;
                }
            }

            cameraCharacters[strlIndex] ??= [];

            cameraCharacters[strlIndex].push(character);

            strlCharacters.push(character);

            characters.add(character);
        }

        strumLines.add(new StrumLine(strl, notes[strlIndex] ?? [], SONG.speed, strlCharacters));
    }
}

function initControls()
{
    FlxG.stage.addEventListener('keyDown', justPressedKey);
    FlxG.stage.addEventListener('keyUp', justReleasedKey);
}

function justPressedKey(event:KeyboardEvent)
{
    if (FlxG.keys.firstJustPressed() <= -1)
        return;

    strumLines.forEachAlive(
        (strl) -> {
            strl.justPressedKey(event.keyCode);
        }
    );
}

function justReleasedKey(event:KeyboardEvent)
{
    strumLines.forEachAlive(
        (strl) -> {
            strl.justReleasedKey(event.keyCode);
        }
    );
}

function loadSong()
{
    initStrumLines();

    Conductor.bpm = SONG.bpm;
}

var camFollow:FlxObject;

function initCamera()
{
    camFollow = new FlxObject(1, 1, 0, 0);

    camGame.follow(camFollow);

    camGame.followLerp = 2.5 * STAGE.speed ?? 1;

    camGame.zoom = STAGE.zoom;
}

function onUpdate(elapsed:Float)
{
    Conductor.songPosition = FlxG.sound.music.time;
}

function onSectionHit(curSection:Int)
{
    final songSection:ALESongSection = SONG.sections[curSection];

    if (songSection == null)
        return;

    final character:Character = cameraCharacters[songSection.camera[0]][songSection.camera[1]];

    camFollow.x = character.getMidpoint().x + character.data.cameraPosition.x * (character.type == 'player' ? -1 : 1);
    camFollow.y = character.getMidpoint().y + character.data.cameraPosition.y;
}

function onBeatHit(curBeat:Int)
{
    characters.forEachAlive(
        (char) -> {
            char.dance();
        }
    );
}

function onDestroy()
{
    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);
}

// ------- ADRIANA SALTE -------

function onHotReloadingConfig()
{
    for (pack in ['utils', 'funkin.visuals.game', 'funkin.visuals.objects'])
        for (file in Paths.readDirectory('scripts/classes/' + pack.replace('.', '/')))
            addHotReloadingFile('scripts/classes/' + pack.replace('.', '/') + '/' + file);
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