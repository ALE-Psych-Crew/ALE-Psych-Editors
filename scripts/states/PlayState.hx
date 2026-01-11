import lime.app.Application;

import flixel.math.FlxPoint;

import utils.ALEFormatter;

import funkin.visuals.game.StrumLine;

using StringTools;

static var SONG:ALESong;

function onCreate()
{
    ClientPrefs.data.downScroll = false;

    if (SONG == null)
        SONG = ALEFormatter.getSong('fresh', 'hard');

    FlxG.sound.playMusic(Paths.inst('songs/fresh'));

    loadSong();
}

function loadSong()
{
    initStrumLines();
}

public var strumLines:FlxTypedGroup<StrumLine>;

function initStrumLines()
{
    final notes:Array<Array<Dynamic>> = [];

    for (section in SONG.sections)
    {
        for (note in section.notes)
        {
            notes[note[4][0]] ??= [];

            notes[note[4][0]].push(
                [
                    note[0],
                    note[1],
                    note[2],
                    note[3],
                    note[4][1]
                ]
            );
        }
    }

    strumLines = new FlxTypedGroup<StrumLine>();
    add(strumLines);

    for (strlIndex => strl in SONG.strumLines)
        strumLines.add(new StrumLine(strl, notes[strlIndex] ?? [], SONG.speed));
}

// ------- ADRIANA SALTE -------

function onHotReloadingConfig()
{
    for (file in ['utils.ALEFormatter', 'funkin.visuals.game.StrumLine', 'funkin.visuals.game.Strum', 'funkin.visuals.game.ALENote'])
        addHotReloadingFile('scripts/classes/' + file.replace('.', '/') + '.hx');
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