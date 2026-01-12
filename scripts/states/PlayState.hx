import lime.app.Application;

import flixel.math.FlxPoint;

import utils.ALEFormatter;

import funkin.visuals.game.StrumLine;

using StringTools;

var SONG:ALESong;

var instSound:openfl.media.Sound;

function new(?song:String, ?difficulty:String)
{
    SONG ??= ALEFormatter.getSong(song ?? 'bopeebo', difficulty ?? 'hard');

    instSound = Paths.voices('songs/' + (song ?? 'bopeebo'));
}

function onCreate()
{
    FlxG.sound.playMusic(instSound);

    loadSong();
}

function loadSong()
{
    add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(50, 50, 50)));

    initStrumLines();
}

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

    strumLines = new FlxTypedGroup<StrumLine>();
    add(strumLines);
    strumLines.cameras = [camHUD];

    for (strlIndex => strl in SONG.strumLines)
        strumLines.add(new StrumLine(strl, notes[strlIndex] ?? [], SONG.speed));
}

function onUpdate(elapsed:Float)
{
    Conductor.songPosition = FlxG.sound.music.time;
}

camGame.zoom = camHUD.zoom = 0.75;

// ------- ADRIANA SALTE -------

function onHotReloadingConfig()
{
    for (file in ['utils.ALEFormatter', 'funkin.visuals.game.StrumLine', 'funkin.visuals.game.Strum', 'funkin.visuals.game.Splash', 'funkin.visuals.game.Note'])
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