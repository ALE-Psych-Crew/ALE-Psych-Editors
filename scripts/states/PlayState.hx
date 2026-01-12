import lime.app.Application;

import flixel.math.FlxPoint;

import utils.ALEFormatter;

import funkin.visuals.game.StrumLine;

import funkin.visuals.game.Character;

using StringTools;

var SONG:ALESong;

var instSound:openfl.media.Sound;

function new(?song:String, ?difficulty:String)
{
    SONG ??= ALEFormatter.getSong(song ?? 'bopeebo', difficulty ?? 'hard');

    instSound = Paths.voices('songs/' + (song ?? 'bopeebo'));
}

function postCreate()
{
    FlxG.sound.playMusic(instSound);

    ClientPrefs.data.botplay = false;

    loadSong();
}

var characters:FlxTypedGroup<Character>;

var strumLines:FlxTypedGroup<StrumLine>;

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
            strlCharacters.push(characters.add(new Character(character, strl.type)));

        strumLines.add(new StrumLine(strl, notes[strlIndex] ?? [], SONG.speed, strlCharacters));
    }
}

function onUpdate(elapsed:Float)
{
    Conductor.songPosition = FlxG.sound.music.time;
}

function loadSong()
{
    add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(50, 50, 50)));

    initStrumLines();

    Conductor.bpm = SONG.bpm;
}

function onBeatHit(curBeat:Int)
{
    characters.forEachAlive(
        (char) -> {
            char.dance();
        }
    );
}

camGame.zoom = camHUD.zoom = 1;

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