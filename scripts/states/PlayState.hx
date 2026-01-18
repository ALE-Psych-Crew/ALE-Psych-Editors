import lime.app.Application;

import flixel.FlxBasic;
import flixel.text.FlxTextBorderStyle;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.FlxObject;

import utils.ALEFormatter;

import haxe.Timer;

import haxe.ds.StringMap;

import funkin.visuals.game.StrumLine;
import funkin.visuals.game.NeoCharacter as Character;

import funkin.visuals.objects.NeoBar as Bar;
import funkin.visuals.objects.Icon;

import funkin.visuals.FXCamera;

//import core.structures.ALESong;
//import core.structures.ALESongSection;

//import core.structures.Point;

using StringTools;

var SONG:ALESong;
var STAGE:ALEStage;

var instSound:openfl.media.Sound;

var characters:FlxTypedGroup<Character>;
var opponents:FlxTypedGroup<Character>;
var players:FlxTypedGroup<Character>;
var extras:FlxTypedGroup<Character>;

var strumLines:FlxTypedGroup<StrumLine>;

var cameraCharacters:Array<Array<Character>> = [];

var healthBar:Bar;

var icons:FlxTypedGroup<Icon>;
var playerIcon:Icon;
var opponentIcon:Icon;

var scoreText:FlxText;

var camFollow:FlxObject;

var stageObjects:StringMap<FlxSprite> = new StringMap<FlxSprite>();

final vocals:Array<FlxSound> = [];

var score:Float = 0;
var totalPlayed:Int = 0;
var accuracyMod:Float = 0;
var misses:Int = 0;

var health(default, set):Float = 1;
var botplay(default, set):Bool;

var dad(get, never):Character;
function get_dad():Character
    return opponents.members[0];

var boyfriend(get, never):Character;
function get_boyfriend():Character
    return players.members[0];

var gf(get, never):Character;
function get_gf():Character
    return extras.members[0];

var iconP1(get, never):Icon;
function get_iconP1():Icon
    return playerIcon;

var iconP2(get, never):Icon;
function get_iconP2():Icon
    return opponentIcon;

var scoreTxt(get, never):FlxText;
function get_scoreTxt():FlxText
    return scoreText;

var accuracy(get, never):Float;
function get_accuracy():Float
    return totalPlayed == 0 ? 0 : accuracyMod / totalPlayed;

public function calculateBPMChanges(?song:Null<ALESong>)
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

function set_botplay(value:Bool):Bool
{
    botplay = value;

    for (strl in strumLines)
        strl.botplay = strl.type != 'player' || botplay;

    return botplay;
}

function set_health(value:Float):Float
{
    health = FlxMath.bound(value, 0, 2);
    updateHealth();
    return health;
}

function new(?song:String, ?difficulty:String)
{
    song ??= 'bopeebo';
    difficulty ??= 'hard';

    SONG ??= ALEFormatter.getSong(song, difficulty);
    STAGE ??= ALEFormatter.getStage(SONG.stage);

    calculateBPMChanges(SONG);

    instSound = Paths.inst('songs/' + (song));
    
    for (path in [''])
    {
        var sound:FlxSound = new FlxSound().loadEmbedded(Paths.voices('songs/' + song, path));
        add(sound);

        FlxG.sound.list.add(sound);

        vocals.push(sound);
    }
}

var camGame:FXCamera;

function onCreate()
{
    ClientPrefs.data.downScroll = false;
    ClientPrefs.data.botplay = true;

    initCamera();
    initSong();
    initStage();
    initControls();
    initHud();
    initMusic();
}

function initMusic()
{
    for (sound in vocals)
        sound.play(sound);

    FlxG.sound.playMusic(instSound, 0.75, false);
}

function onUpdate(elapsed:Float)
{
    if (FlxG.sound.music.playing)
        Conductor.songPosition += elapsed * 1000;

    scoreText.text = ClientPrefs.data.botplay
        ? 'BOTPLAY'
        : 'Score: ' + score + '    Misses: ' + misses + '    Accuracy: ' + CoolUtil.floorDecimal(accuracy, 2) + '%';

    if (Controls.RESET)
    {
        FlxG.sound.music?.pause();
        FlxG.resetState();
    }
}

function onSectionHit()
{
    final songSection:ALESongSection = SONG.sections[curSection];

    if (songSection == null)
        return;

    final character:Character = cameraCharacters[songSection.camera[0]][songSection.camera[1]];

    camGame.position.x = character.getMidpoint().x + character.data.cameraPosition.x * (character.type == 'player' ? -1 : 1);
    camGame.position.y = character.getMidpoint().y + character.data.cameraPosition.y;

    if (STAGE.cameraOffset != null)
    {
        var offset:Point = null;

        if (STAGE.cameraOffset.type != null)
            offset = Reflect.getProperty(STAGE.cameraOffset.type, cast character.type);

        if (STAGE.cameraOffset.id != null)
            offset = Reflect.getProperty(STAGE.cameraOffset.id, character.id);

        if (offset != null)
        {
            camGame.position.x += offset.x ?? 0;
            camGame.position.y += offset.y ?? 0;
        }
    }
}

function onStepHit()
{
    if (FlxG.sound.music != null && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
    {
        final timeSub:Float = Conductor.songPosition - Conductor.offset;
        final syncTime:Float = 20;

        for (audio in [FlxG.sound.music].concat(vocals))
        {
            if (audio != null && audio.length > 0)
            {
                if (Math.abs(audio.time - timeSub) > syncTime)
                {
                    resyncVocals();

                    break;
                }
            }
        }
    }
}

function onBeatHit(curBeat:Int)
{
    characters.forEachAlive(char -> char.dance());

    icons.forEachAlive(icon -> icon.bop(curBeat));

    for (camera in [camGame, camHUD])
        camera.bop(curBeat);
}

function onDestroy()
{
    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);
}

function initHud()
{
    healthBar = new Bar(0, FlxG.height * (ClientPrefs.data.downScroll ? 0.1 : 0.9), 50, true);
    healthBar.x = FlxG.width / 2 - healthBar.width / 2;
    healthBar.cameras = [camHUD];
    add(healthBar);

    icons = new FlxTypedGroup<Icon>();

    playerIcon = new Icon('player');
    playerIcon.cameras = [camHUD];
    addIcon(playerIcon);

    opponentIcon = new Icon('opponent');
    opponentIcon.cameras = [camHUD];
    addIcon(opponentIcon);

    if (dad != null)
    {
        healthBar.rightBar.color = CoolUtil.colorFromString(dad.data.barColor);
        opponentIcon.change(dad.data.icon);
    } else {
        healthBar.rightBar.color = FlxColor.BLACK;
        opponentIcon.visible = false;
    }

    if (boyfriend != null)
    {
        healthBar.leftBar.color = CoolUtil.colorFromString(boyfriend.data.barColor);
        playerIcon.change(boyfriend.data.icon);
    } else {
        healthBar.leftBar.color = FlxColor.BLACK;
        playerIcon.visible = false;
    }

    scoreText = new FlxText(0, healthBar.y + 40, FlxG.width, 'Score      Misses      Rating');
    scoreText.setFormat(Paths.font('vcr.ttf'), 17, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.borderSize = 1.25;
    scoreText.cameras = [camHUD];
    add(scoreText);
}

function addIcon(icon:Icon)
{
    icon.bar = healthBar;

    icons.add(icon);

    add(icon);
}

function updateHealth()
{
    healthBar.percent = health * 50;

    if (health <= 0)
    {
        FlxG.sound.music.pause();

        CoolUtil.openSubState(new CustomSubState(CoolVars.data.gameOverScreen));
    }
}

function postUpdate()
{
    health = Math.sin(Conductor.songPosition / 500) * 0.9 + 1;
}

function initStrumLines()
{
    final notes:Array<Array<Dynamic>> = [];

    /*
    Conductor.bpm = SONG.bpm;

    if (true)
    {
        for (section in SONG.sections)
        {
            if (section.changeBPM)
                Conductor.bpm = section.bpm;

            for (note in section.notes)
            {
                notes[note[4][0]] ??= [];
                notes[note[4][0]].push([
                    note[0],
                    note[1],
                    note[2],
                    note[3],
                    note[4][1],
                    Conductor.stepCrochet
                ]);
            }
        }

        Conductor.bpm = SONG.bpm;
    }
    */

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
                var offset:Point = null;

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

        final strumLine:StrumLine = new StrumLine(strl, notes[strlIndex] ?? [], SONG.speed, strlCharacters);

        strumLine.onHitNote = (note, rating, removeNote) ->
        {
            if (note.character.type == 'player')
            {
                health = health + note.hitHealth;

                score += ratingToScore(rating);

                if (note.type == 'note')
                {
                    accuracyMod += ratingToAccuracy(rating);

                    totalPlayed++;
                }
            }
            return null;
        };

        strumLine.onMissNote = (note) ->
        {
            if (note.character.type == 'player')
            {
                if (note.type == 'note')
                {
                    health = health - note.missHealth;

                    misses++;

                    totalPlayed++;
                }
            }
            return null;
        };

        strumLines.add(strumLine);
    }
}

function ratingToAccuracy(rating:Rating):Float
{
    return switch (cast rating)
    {
        case 'sick': 100;
        case 'good': 67;
        case 'bad': 33;
        default: 0;
    };
}

function ratingToScore(rating:Rating):Float
{
    return switch (cast rating)
    {
        case 'sick': 350;
        case 'good': 200;
        case 'bad': 100;
        case 'shit': 50;
        default: 0;
    };
}

function addCharacter(character:Character)
{
    switch (character.type)
    {
        case 'opponent': opponents.add(character);
        case 'player': players.add(character);
        case 'extra': extras.add(character);
        default:
    }

    characters.add(character);
    add(character);
}

inline function addBehindOpponents(obj:FlxBasic)
    addBehindGroup(opponents, obj);

inline function addBehindPlayers(obj:FlxBasic)
    addBehindGroup(players, obj);

inline function addBehindExtras(obj:FlxBasic)
    addBehindGroup(extras, obj);

inline function addBehindDad(obj:FlxBasic)
    addBehindGroup(opponents, obj);

inline function addBehindBF(obj:FlxBasic)
    addBehindGroup(players, obj);

inline function addBehindGF(obj:FlxBasic)
    addBehindGroup(extras, obj);

function addBehindGroup(group:FlxTypedGroup<Dynamic>, obj:FlxBasic)
{
    insert(members.indexOf(group.members[0]), obj);
}

function initStage()
{
    if (STAGE.objectsConfig != null)
    {
        final config = STAGE.objectsConfig;

        for (object in config.objects)
        {
            final obj:FlxSprite =
                Type.createInstance(
                    Type.resolveClass(object.classPath ?? 'flixel.FlxSprite'),
                    object.classArguments ?? []
                );

            obj.loadGraphic(Paths.image('stages/' + config.directory + '/' + (object.path ?? object.id)));

            for (props in [config.properties, object.properties])
                if (props != null)
                    CoolUtil.setMultiProperty(obj, props);

            var addMethod:FlxBasic->Dynamic = null;

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

function initControls()
{
    FlxG.stage.addEventListener('keyDown', justPressedKey);
    FlxG.stage.addEventListener('keyUp', justReleasedKey);
}

function justPressedKey(event:KeyboardEvent)
{
    if (FlxG.keys.firstJustPressed() <= -1)
        return;

    strumLines.forEachAlive(strl -> strl.justPressedKey(event.keyCode));
}

function justReleasedKey(event:KeyboardEvent)
{
    strumLines.forEachAlive(strl -> strl.justReleasedKey(event.keyCode));
}

function initSong()
{
    initStrumLines();

    Conductor.bpm = SONG.bpm;
}

function initCamera()
{
    camGame = new FXCamera(STAGE.speed ?? 1);
    camGame.zoomSpeed = 1;
    camGame.bopModulo = 4;
    camGame.targetZoom = STAGE.zoom;

    FlxG.cameras.reset(camGame);
        
    camHUD = new FXCamera();
    camHUD.zoomSpeed = 1;
    camHUD.bopModulo = 4;
    camHUD.bopZoom = 2;
    
    FlxG.cameras.add(camHUD, false);
}

function resyncVocals()
{
    if (FlxG.sound.music != null)
        Conductor.songPosition = FlxG.sound.music.time;

    for (vocal in vocals)
        if (vocal != null)
        {
            vocal.pause();

            if (Conductor.songPosition <= vocal.length)
                vocal.time = Conductor.songPosition;
            
            vocal.play();
        }
}

function updateIconsPosition()
{
    final isRight:Bool = icon.type == 'player' == healthBar.rightToLeft;

    icon.x = isRight ? (barMiddle.x - icon.offsetX) : (barMiddle.x - icon.width + icon.offsetX);
    icon.y = barMiddle.y - icon.height / 2 + icon.offsetY;

    if (icon.flipX != isRight)
        icon.flipX = isRight;
}

// ------- ADRIANA SALTE -------

function onHotReloadingConfig()
{
    for (pack in ['utils', 'funkin.visuals.game', 'funkin.visuals.objects', 'funkin.visuals'])
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