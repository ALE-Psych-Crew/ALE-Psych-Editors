import lime.app.Application;

import flixel.FlxBasic;
import flixel.text.FlxTextBorderStyle;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.FlxObject;

import utils.ALEFormatter;

import haxe.Timer;

import haxe.ds.StringMap;
import haxe.ds.GenericStack;

import funkin.visuals.game.StrumLine;
import funkin.visuals.game.NeoCharacter as Character;

import funkin.visuals.objects.NeoBar as Bar;
import funkin.visuals.objects.Icon;

import funkin.visuals.FXCamera;

//import core.structures.ALESong;
//import core.structures.ALEStage;
//import core.structures.ALESongSection;
//import core.structures.ALEHud;

//import core.structures.Point;

import funkin.visuals.objects.FunkinSprite;

import animate.FlxAnimateFrames;

using StringTools;

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

// ------- ADRIANA SALTE -------

var CHART:ALESong;
var STAGE:ALEStage;
var HUD:ALEHud;

var characters:FlxTypedGroup<Character>;
var opponents:FlxTypedGroup<Character>;
var players:FlxTypedGroup<Character>;
var extras:FlxTypedGroup<Character>;

var strumLines:FlxTypedGroup<StrumLine>;

var strums:FlxTypedGroup<Strum>;

var strumLineNotes(get, never):FlxTypedGroup<Strum>;
function get_strumLineNotes():FlxTypedGroup
    return strums;

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

var uiGroup:FlxTypedGroup<FlxBasic>;

var combo:Int = 0;

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

final song:String;

final difficulty:String;

function new(?songName:String, ?diff:String)
{
    song = songName ?? 'bopeebo';
    difficulty = diff ?? 'hard';

    CHART ??= ALEFormatter.getSong(song, difficulty);
    STAGE ??= ALEFormatter.getStage(CHART.stage);
    HUD ??= ALEFormatter.getHud(STAGE.hud);

    calculateBPMChanges(CHART);
}

var camGame:FXCamera;

function onCreate()
{
    ClientPrefs.data.downScroll = false;

    ClientPrefs.data.botplay = true;

    initCamera();

    initStrumLines();

    botplay = ClientPrefs.data.botplay;

    initEvents();

    initStage();
    initControls();
    initHud();

    cacheCombo();
    cacheSounds();

    startCountdown();
}

final eventsListStack:GenericStack<ALEEventList> = new GenericStack();

function initEvents()
{
    final tempEvents:Array<Array<Dynamic>> = CHART.events.copy();

    for (i in 0...tempEvents.length)
    {
        final targetEvent:Array<Dynamic> = tempEvents[tempEvents.length - 1 - i];

        eventsListStack.add({
            time: targetEvent[0],
            events: [
                for (event in targetEvent[1])
                {
                    id: event.shift(),
                    values: event
                }
            ]
        });
    }
}

final soundsMap:StringMap<Sound> = new StringMap();

function cacheSounds()
{
    soundsMap.set('::MUSIC', Paths.inst('songs/' + song));

    final voices:Sound = Paths.voices('songs/' + song, '', false, false);

    if (voices != null)
        soundsMap.set('::VOICES', voices);

    final playerVoices:Sound = Paths.voices('songs/' + song, 'Player', false, false);

    if (playerVoices != null)
        soundsMap.set('::PLAYER', playerVoices);

    final opponentVoices:Sound = Paths.voices('songs/' + song, 'Opponent', false, false);

    if (opponentVoices != null)
        soundsMap.set('::OPPONENT', opponentVoices);

    final extraVoices:Sound = Paths.voices('songs/' + song, 'Extra', false, false);

    if (extraVoices != null)
        soundsMap.set('::EXTRA', extraVoices);

    characters.forEachAlive((char) -> {
        final voice:Sound = Paths.voices('songs/' + song, char.id, false, false);

        if (voice != null)
            soundsMap.set(char.id, voice);
    }); 
}

function addVocal(vocal:Sound)
{
    if (vocal == null)
        return;

    vocals.push(vocal);

    FlxG.sound.list.add(vocal);
}

var camOther:FXCamera;

var countdownSprite:FlxSprite;

var allowSongPositionUpdate:Bool = false;

var skipCountdown:Bool = false;

function startCountdown()
{
    if (skipCountdown)
    {
        startSong();
        
        return;
    }

    final scriptResult:Array<Dynamic> = [];

    countdownSprite = new FlxSprite();
    countdownSprite.alpha = 0;
    countdownSprite.cameras = [camOther];
    countdownSprite.antialiasing = HUD.antialiasing && ClientPrefs.data.antialiasing;

    add(countdownSprite);
    
    final ids:Array<String> = [null, 'ready', 'set', 'go'];

    final graphics:Array<FlxGraphic> = [for (spr in ids) spr == null ? null : Paths.image('hud/' + STAGE.hud + '/countdown/' + spr)];

    final sounds:Array<Sound> = [for (spr in ['three', 'two', 'one', 'go']) spr == null ? null : Paths.sound('hud/' + STAGE.hud + '/countdown/' + spr)];

    if (!scriptResult.contains(CoolVars.Function_Stop))
    {
        allowSongPositionUpdate = true;
        
        Conductor.songPosition = -Conductor.crochet * 5;

        FlxTimer.loop(Conductor.crochet / 1000, (loop) -> {
            if (loop == 5)
            {
                remove(countdownSprite);
                
                allowSongPositionUpdate = false;

                startSong();

                return;
            }

            final scriptResult:Array<Dynamic> = [];

            if (!scriptResult.contains(CoolVars.Function_Stop))
            {
                final graphic:FlxGraphic = graphics[loop - 1];

                FlxG.sound.play(sounds[loop - 1]);

                if (graphic != null)
                {
                    countdownSprite.loadGraphic(graphic);

                    FlxTween.cancelTweensOf(countdownSprite);
                    FlxTween.cancelTweensOf(countdownSprite.scale);

                    countdownSprite.scale.x = countdownSprite.scale.y = HUD.countdown.scale;
                    countdownSprite.alpha = HUD.countdown.alpha;

                    countdownSprite.updateHitbox();
                    countdownSprite.screenCenter();

                    FlxTween.tween(countdownSprite.scale, {x: HUD.countdown.endScale, y: HUD.countdown.endScale}, Conductor.crochet / 1000 * HUD.countdown.beats, {ease: easeByString(HUD.countdown.scaleEase)});

                    FlxTween.tween(countdownSprite, {alpha: HUD.countdown.endAlpha}, Conductor.crochet / 1000 * HUD.countdown.beats, {ease: easeByString(HUD.countdown.alphaEase)});

                    characters.forEachAlive((char) -> {
                        char.dance(loop - 1);
                    });
                }
            }

            // POST
        }, 5);
    }

    // POST
}

function easeByString(?ease:String = '')
{
    return switch(ease.toLowerCase().trim())
    {
        case 'backin':
            FlxEase.backIn;
        case 'backinout':
            FlxEase.backInOut;
        case 'backout':
            FlxEase.backOut;
        case 'bouncein':
            FlxEase.bounceIn;
        case 'bounceinout':
            FlxEase.bounceInOut;
        case 'bounceout':
            FlxEase.bounceOut;
        case 'circin':
            FlxEase.circIn;
        case 'circinout':
            FlxEase.circInOut;
        case 'circout':
            FlxEase.circOut;
        case 'cubein':
            FlxEase.cubeIn;
        case 'cubeinout':
            FlxEase.cubeInOut;
        case 'cubeout':
            FlxEase.cubeOut;
        case 'elasticin':
            FlxEase.elasticIn;
        case 'elasticinout':
            FlxEase.elasticInOut;
        case 'elasticout':
            FlxEase.elasticOut;
        case 'expoin':
            FlxEase.expoIn;
        case 'expoinout':
            FlxEase.expoInOut;
        case 'expoout':
            FlxEase.expoOut;
        case 'quadin':
            FlxEase.quadIn;
        case 'quadinout':
            FlxEase.quadInOut;
        case 'quadout':
            FlxEase.quadOut;
        case 'quartin':
            FlxEase.quartIn;
        case 'quartinout':
            FlxEase.quartInOut;
        case 'quartout':
            FlxEase.quartOut;
        case 'quintin':
            FlxEase.quintIn;
        case 'quintinout':
            FlxEase.quintInOut;
        case 'quintout':
            FlxEase.quintOut;
        case 'sinein':
            FlxEase.sineIn;
        case 'sineinout':
            FlxEase.sineInOut;
        case 'sineout':
            FlxEase.sineOut;
        case 'smoothstepin':
            FlxEase.smoothStepIn;
        case 'smoothstepinout':
            FlxEase.smoothStepInOut;
        case 'smoothstepout':
            FlxEase.smoothStepOut;
        case 'smootherstepin':
            FlxEase.smootherStepIn;
        case 'smootherstepinout':
            FlxEase.smootherStepInOut;
        case 'smootherstepout':
            FlxEase.smootherStepOut;
        default:
            FlxEase.linear;
    }
}

function changeCharacter(char:Character, newChar:String)
{
    char.change(newChar);

    if (char == boyfriend)
    {
        playerIcon.change(char.data.icon);

        healthBar.leftBar.color = CoolUtil.colorFromString(char.data.barColor);
    }

    if (char == dad)
    {
        opponentIcon.change(char.data.icon);

        healthBar.rightBar.color = CoolUtil.colorFromString(char.data.barColor);
    }

    resetCharacterPosition(char);
}

function startSong()
{
    FlxG.sound.playMusic(soundsMap.get('::MUSIC'), 0.85, false);

    final voices:Null<FlxSound> = null;

    if (soundsMap.exists('::VOICES'))
        voices = new FlxSound().loadEmbedded(soundsMap.get('::VOICES'));

    final playerVoices:Null<FlxSound> = null;

    if (soundsMap.exists('::PLAYER'))
        playerVoices = new FlxSound().loadEmbedded(soundsMap.get('::PLAYER'));

    final opponentVoices:Null<FlxSound> = null;

    if (soundsMap.exists('::OPPONENT'))
        opponentVoices = new FlxSound().loadEmbedded(soundsMap.get('::OPPONENT'));

    final extraVoices:Null<FlxSound> = null;

    if (soundsMap.exists('::EXTRA'))
        extraVoices = new FlxSound().loadEmbedded(soundsMap.get('::EXTRA'));

    for (sound in [voices, playerVoices, opponentVoices, extraVoices])
        if (sound != null)
            addVocal(sound);

    final existingCharactersVocals:StringMap<FlxSound> = new StringMap();

    characters.forEachAlive((char) ->
    {
        if (voices != null)
            char.vocals.push(voices);

        final defaultVoice:Null<FlxSound> = switch (cast char.type)
        {
            case 'player':
                playerVoices;

            case 'opponent':
                opponentVoices;

            case 'extra':
                extraVoices;

            default:
                null;
        };

        if (defaultVoice != null)
            char.vocals.push(defaultVoice);

        final voice:Null<FlxSound> = null;

        if (existingCharactersVocals.exists(char.id))
        {
            voice = existingCharactersVocals.get(char.id);
        } else if (soundsMap.exists(char.id)) {
            voice = new FlxSound().loadEmbedded(soundsMap.get(char.id));

            addVocal(voice);

            existingCharactersVocals.set(char.id);
        }

        if (voice != null)
            char.vocals.push(voice);
    });

    for (voice in vocals)
        voice.play();

    Conductor.songPosition = 0;
}

function onUpdate(elapsed:Float)
{
    if ((FlxG.sound.music != null && FlxG.sound.music.playing) || allowSongPositionUpdate)
        Conductor.songPosition += elapsed * 1000;

    while (!eventsListStack.isEmpty() && eventsListStack.first().time <= Conductor.songPosition)
        for (event in eventsListStack.pop().events)
            eventHit(event);

    scoreText.text = botplay ? 'BOTPLAY' : 'Score: ' + score + '    Misses: ' + misses + '    Accuracy: ' + CoolUtil.floorDecimal(accuracy, 2) + '%';

    if (Controls.RESET)
    {
        pauseMusic();
        
        FlxG.resetState();
    }
}

function eventHit(event:ALEEvent)
{
}

function onSectionHit()
{
    final songSection:ALESongSection = CHART.sections[curSection];

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
    characters.forEachAlive(char -> char.dance(curBeat));

    icons.forEachAlive(icon -> icon.bop(curBeat));

    for (camera in [camGame, camHUD])
        camera.bop(curBeat);
}

function onDestroy()
{
    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);
    
    pauseMusic();
}

function pauseMusic()
{
    FlxG.sound.music?.pause();

    for (sound in vocals)
        if (sound != null)
            sound.pause();
}

function initHud()
{
    add(uiGroup = new FlxTypedGroup<FlxBasic>());

    uiGroup.cameras = [camHUD];

    healthBar = new Bar('hud/' + STAGE.hud + '/bar', 0, FlxG.height * (ClientPrefs.data.downScroll ? 0.1 : 0.9), 50, true);
    healthBar.x = FlxG.width / 2 - healthBar.width / 2;
    uiGroup.add(healthBar);

    icons = new FlxTypedGroup<Icon>();

    playerIcon = new Icon('player');
    addIcon(playerIcon);

    opponentIcon = new Icon('opponent');
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

    uiGroup.add(scoreText);
}

function addIcon(icon:Icon)
{
    icon.bar = healthBar;

    icons.add(icon);

    uiGroup.add(icon);
}

function updateHealth()
{
    healthBar.percent = health * 50;

    if (health <= 0)
    {
        pauseMusic();

        CoolUtil.openSubState(new CustomSubState(CoolVars.data.gameOverScreen));
    }
}

var spawnNotes:Bool = false;

function postUpdate(elapsed:Float)
{
    health = Math.sin(Conductor.songPosition / 1000) * 0.9 + 1;
}

function postCreate()
{
}

function initStrumLines()
{
    final notes:Array<Array<Dynamic>> = [];

    Conductor.bpm = CHART.bpm;

    if (spawnNotes)
    {
        for (section in CHART.sections)
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

        Conductor.bpm = CHART.bpm;
    }

    Conductor.bpm = CHART.bpm;

    characters = new FlxTypedGroup<Character>();
    opponents = new FlxTypedGroup<Character>();
    players = new FlxTypedGroup<Character>();
    extras = new FlxTypedGroup<Character>();

    add(strumLines = new FlxTypedGroup<StrumLine>());

    strumLines.cameras = [camHUD];

    strums = new FlxTypedGroup<Strum>();

    for (strlIndex => strl in CHART.strumLines)
    {
        final strlCharacters:Array<Character> = [];

        for (char in strl.characters)
        {
            final character:Character = new Character(char, strl.type);

            cameraCharacters[strlIndex] ??= [];

            cameraCharacters[strlIndex].push(character);

            strlCharacters.push(character);
            
            addCharacter(character);
        }

        final strumLine:StrumLine = new StrumLine(strl, notes[strlIndex] ?? [], CHART.speed, strlCharacters);

        strumLine.onHitNote = (note, rating, character, removeNote) ->
        {
            if (character.type == 'player')
            {
                health = health + note.hitHealth;

                score += ratingToScore(rating);

                if (note.type == 'note')
                {
                    accuracyMod += ratingToAccuracy(rating);

                    totalPlayed++;

                    combo++;

                    displayCombo(rating);
                }
            }

            return null;
        };

        strumLine.onMissNote = (note, character) ->
        {
            if (character.type == 'player')
            {
                if (note.type == 'note')
                {
                    combo = 0;

                    health = health - note.missHealth;

                    misses++;

                    totalPlayed++;
                }
            }

            return null;
        };

        strumLines.add(strumLine);

        for (strum in strumLine.strums)
            strums.add(strum);
    }
}

var comboGroup:FlxTypedSpriteGroup<FlxSprite>;

var comboSprite:FlxSprite;

var comboNumbers:Array<FlxSprite> = [];

function cacheCombo()
{
    for (obj in ['sick', 'good', 'bad', 'sick'].concat([for (i in 0...10) '$i']))
        Paths.image('hud/' + STAGE.hud + '/combo/' + obj);
    
    add(comboGroup = new FlxTypedSpriteGroup<FlxSprite>(HUD.combo.position.x, HUD.combo.position.y));
    comboGroup.cameras = [camHUD];

    comboSprite = new FlxSprite();
    comboSprite.scale.x = comboSprite.scale.y = HUD.combo.scale;

    comboGroup.add(comboSprite);

    for (i in 0...3)
    {
        final number:FlxSprite = new FlxSprite();
        number.scale.x = number.scale.y = HUD.combo.numberScale;
        
        comboGroup.add(number);

        comboNumbers.push(number);
    }

    for (spr in comboGroup)
    {
        spr.alpha = 0;

        spr.antialiasing = HUD.antialiasing && ClientPrefs.data.antialiasing;
    }
}

function displayCombo(rating:Rating)
{
    final path:String = 'hud/' + STAGE.hud + '/combo';

    FlxTween.cancelTweensOf(comboSprite);

    comboSprite.loadGraphic(Paths.image(path + '/' + Std.string(rating)));
    comboSprite.alpha = HUD.combo.alpha;
    comboSprite.updateHitbox();
    comboSprite.x = comboGroup.x - comboSprite.width / 2;
    comboSprite.y = comboGroup.y - comboSprite.height / 2;

    FlxTween.tween(comboSprite, {x: comboSprite.x + FlxG.random.float(-HUD.combo.endPosition.x, HUD.combo.endPosition.x), y: comboSprite.y + HUD.combo.endPosition.y, alpha: 0}, HUD.combo.duration, {ease: easeByString(HUD.combo.ease)});

    final comboString:String = '${combo % 1000}'.lpad('0', 3);

    final numberOffset:Float = FlxG.random.float(-HUD.combo.numberEndPosition.x, HUD.combo.numberEndPosition.x);

    for (index => number in comboNumbers)
    {
        FlxTween.cancelTweensOf(number);

        number.loadGraphic(Paths.image(path + '/' + comboString.charAt(index)));
        number.updateHitbox();
        number.alpha = HUD.combo.numberAlpha;
        number.x = comboGroup.x + HUD.combo.numberPosition.x + HUD.combo.space * index - number.width / 2;
        number.y = comboGroup.y + HUD.combo.numberPosition.y - number.height / 2;

        FlxTween.tween(number, {x: number.x + numberOffset, y: number.y + HUD.combo.numberEndPosition.y, alpha: 0}, HUD.combo.numberDuration, {ease: easeByString(HUD.combo.numberEase)});
    }
}

function postDestroy()
{
    Paths.cachedJson.clear();
}

function ratingToAccuracy(rating:Rating):Float
{
    return switch (cast rating)
    {
        case 'sick':
            100;
            
        case 'good':
            67;

        case 'bad':
            33;

        default:
            0;
    };
}

function ratingToScore(rating:Rating):Float
{
    return switch (cast rating)
    {
        case 'sick':
            350;

        case 'good':
            200;

        case 'bad':
            100;

        case 'shit':
            50;

        default:
            0;
    };
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

        default:
    }
    
    resetCharacterPosition(character);

    characters.add(character);

    add(character);
}

function resetCharacterPosition(character:Character)
{
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
        
    camOther = new FXCamera();

    FlxG.cameras.add(camOther, false);
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