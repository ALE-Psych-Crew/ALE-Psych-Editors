import lime.app.Application;

import flixel.FlxBasic;

import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.FlxObject;

import utils.ALEFormatter;

import haxe.ds.StringMap;

import funkin.visuals.game.StrumLine;
import funkin.visuals.game.Character;

//import core.structures.ALESong;
//import core.structures.ALESongSection;

//import core.structures.Point;

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
    ClientPrefs.data.downScroll = false;
    ClientPrefs.data.botplay = false;

    ClientPrefs.data.framerate = 60;

    loadSong();

    initStage();

    initControls();

    initCamera();
    
    FlxG.sound.playMusic(instSound);
}

var characters:FlxTypedGroup<Character>;

var opponents:FlxTypedGroup<Character>;
var players:FlxTypedGroup<Character>;
var extras:FlxTypedGroup<Character>;

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

    characters = new FlxTypedGroup<Character>();
    
    opponents = new FlxTypedGroup<Character>();
    players = new FlxTypedGroup<Character>();
    extras = new FlxTypedGroup<Character>();

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

            if (STAGE.characterOffset != null)
            {
                var offset:Point;

                if (STAGE.characterOffset.type != null)
                    offset = Reflect.getProperty(STAGE.characterOffset.type, cast character.type);

                if (STAGE.characterOffset.id != null)
                    offset = Reflect.getProperty(STAGE.characterOffset.id, character.id);

                if (offset != null)
                {
                    character.x += offset.x ?? 0;
                    character.y += offset.y ?? 0;
                }
            }

            cameraCharacters[strlIndex] ??= [];

            cameraCharacters[strlIndex].push(character);

            strlCharacters.push(character);

            addCharacter(character);
        }

        strumLines.add(new StrumLine(strl, notes[strlIndex] ?? [], SONG.speed, strlCharacters));
    }
}

function addCharacter(character:Character)
{
    switch (character.type)
    {
        case 'opponent':
            opponents.add(character);
        case 'player':
            players.add(character);
        case 'extra':
            extras.add(character);
    }

    characters.add(character);

    add(character);
}

function addBehindOpponents(obj:FlxBasic)
    addBehindGroup(opponents, obj);

function addBehindPlayers(obj:FlxBasic)
    addBehindGroup(players, obj);

function addBehindExtras(obj:FlxBasic)
    addBehindGroup(extras, obj);

var addBehindDad:FlxBasic -> Void = this.addBehindOpponents;
var addBehindBF:FlxBasic -> Void = this.addBehindPlayers;
var addBehindGF:FlxBasic -> Void = this.addBehindExtras;

var stageObjects:StringMap<FlxSprite> = new StringMap<FlxSprite>();

function initStage()
{
    if (STAGE.objectsConfig != null)
    {
        final config = STAGE.objectsConfig;

        for (object in config.objects)
        {
            final obj:FlxSprite = Type.createInstance(Type.resolveClass(object.classPath ?? 'flixel.FlxSprite'), object.classArguments ?? []);

            obj.loadGraphic(Paths.image('stages/' + config.directory + '/' + (object.path ?? object.id)));

            for (props in [config.properties, object.properties])
                if (props != null)
                    CoolUtil.setMultiProperty(obj, props);

            var addMethod:FlxBasic -> Dynamic = null;

            #if flixel
            addMethod = Reflect.getProperty(this, object.addMethod ?? 'addBehindExtras');
            #else
            addMethod = Reflect.getProperty(this, 'variables').get(object.addMethod ?? 'addBehindExtras');
            #end

            if (addMethod != null)
                Reflect.callMethod(this, addMethod, [obj]);

            stageObjects.set(object.id, obj);
        }
    }
}

function addBehindGroup(group:FlxTypedGroup, obj:FlxBasic)
    insert(members.indexOf(group.members[0]), obj);

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

    if (STAGE.cameraOffset != null)
    {
        var offset:Point;

        if (STAGE.cameraOffset.type != null)
            offset = Reflect.getProperty(STAGE.cameraOffset.type, cast character.type);

        if (STAGE.cameraOffset.id != null)
            offset = Reflect.getProperty(STAGE.cameraOffset.id, character.id);

        if (offset != null)
        {
            camFollow.x += offset.x ?? 0;
            camFollow.y += offset.y ?? 0;
        }
    }
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