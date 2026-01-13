package funkin.visuals.game;

import utils.ALEFormatter;

import funkin.visuals.game.Strum;
import funkin.visuals.game.Splash;
import funkin.visuals.game.Note;

import flixel.input.keyboard.FlxKey;

import haxe.ds.GenericStack;

/*
import core.structures.ALEStrumLine;
import core.structures.ALESongStrumLine;

import core.enums.CharacterType;
import core.enums.Rating;
*/

class StrumLine extends scripting.haxe.ScriptSpriteGroup
{
    public var strums:FlxTypedSpriteGroup<Strum>;
    public var notes:FlxTypedSpriteGroup<Note>;
    public var splashes:FlxTypedSpriteGroup<Splash>;

    public var botplay:Bool;

    public var unspawnNotes:GenericStack<Note> = new GenericStack<Note>();

    public final config:ALEStrumLine;

    public var inputsArray:Array<Array<FlxKey>>;

    public var scrollSpeed:Float = 1;

    public function new(chartData:ALESongStrumLine, arrayNotes:Array<Dynamic>, speed:Float, characters:Array<Character>)
    {
        super();

        this.scrollSpeed = speed;

        config = ALEFormatter.getStrumLine(chartData.file);

        visible = chartData.visible;

        botplay = chartData.type != 'player' || ClientPrefs.data.botplay;

        add(strums = new FlxTypedSpriteGroup<Strum>());
        
        add(notes = new FlxTypedSpriteGroup<Note>());

        add(splashes = new FlxTypedSpriteGroup<Splash>());

        var inputs = ClientPrefs.controls.notes;

        inputsArray = [inputs.left, inputs.down, inputs.up, inputs.right];

        var strumHeight:Float = 0;

        for (strumIndex => strumConfig in config.strums)
        {
            final strum:Strum = new Strum(strumConfig, strumIndex, config.strumFramerate, config.strumTextures, config.strumScale, config.space);
            strums.add(strum);
            strum.returnToIdle = botplay;

            final splash:Splash = new Splash(strumConfig, strum, config.splashScale, config.splashFramerate, config.splashTextures);
            splashes.add(splash);

            strumHeight = Math.max(strumHeight, strum.height);
        }

        x = chartData.rightToLeft ? config.position.x : FlxG.width - config.position.x - (config.strums.length - 1) * config.space - strums.members[strums.members.length - 1].width;
        y = ClientPrefs.data.downScroll ? FlxG.height - config.position.y - strumHeight : config.position.y;

        var tempNotes:Array<Note> = [];

        for (note in arrayNotes)
        {
            final time:Float = note[0];
            final data:Int = note[1];
            final length:Float = note[2];
            final character:Character = characters[note[4]];
            final type:String = note[3];
            final crochet:Float = note[5];

            final space:Float = config.space;
            final scale:Float = config.noteScale;
            final textures:Array<String> = config.noteTextures;

            final strum:Strum = strums.members[data];

            final strumConfig:ALEStrum = config.strums[data];

            final note:Note = new Note(strumConfig, time, data, length, type, 'note', space, scale, textures, character);

            final parent:Note = note;

            tempNotes.push(note);

            if (length > 0)
            {
                final floorLength:Int = Math.floor(length / crochet);

                for (i in 0...(floorLength + 1))
                {
                    final sustain:Note = new Note(strumConfig, time + i * crochet, data, crochet, type, i == floorLength ? 'end' : 'sustain', space, scale, textures, character);
                    sustain.offsetY = strum.height / 2;
                    sustain.offsetX = strum.width / 2 - sustain.width / 2;
                    sustain.parent = parent;
                    sustain.multAlpha = 0.5;
                    sustain.flipY = ClientPrefs.data.downScroll;

                    if (i != floorLength)
                        sustain.setGraphicSize(sustain.width, crochet * (speed * 0.45) + 2);
                    
                    sustain.updateHitbox();

                    tempNotes.push(sustain);

                    parent = sustain;
                }
            }
        }
        
        tempNotes.sort(
            function(a:Note, b:Note)
            {
                if (a.time == b.time)
                    return a.type == b.type ? 0 : b.type == 'note' ? 1 : -1;

                return a.time > b.time ? -1 : 1;
            }
        );

        for (note in tempNotes)
        {
            note.update(0);
            note.draw();

            unspawnNotes.add(note);
        }
    }

    public function justPressedKey(key:Int)
    {
        if (botplay)
            return;

        for (i in 0...strums.members.length)
        {
            if (inputsArray[i].contains(key))
            {
                keyPressed[i] = true;

                keyJustPressed[i] = true;
            }
        }
    }

    public function justReleasedKey(key:Int)
    {
        if (botplay)
            return;

        for (i in 0...strums.members.length)
        {
            if (inputsArray[i].contains(key))
            {
                keyPressed[i] = false;

                keyJustReleased[i] = true;
            }
        }
    }

    public var spawnTime:Float = 2000;
    public var despawnTime:Float = 650;
    public var missTime:Float = 180;

    var notesToHit:Array<Null<Note>> = [];
    var keyPressed:Array<String> = [];
    var keyJustPressed:Array<Bool> = [];
    var keyJustReleased:Array<Bool> = [];

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        final songPosition:Float = Conductor.songPosition;

        while (!unspawnNotes.isEmpty() > 0 && unspawnNotes.first().time <= songPosition + spawnTime / scrollSpeed)
            notes.add(unspawnNotes.pop());

        notes.forEachAlive(
            (note) -> {
                final strum:Strum = strums.members[note.data];

                if (botplay)
                {
                    if (!note.hit && note.timeDistance <= 0)
                        hitNote(note, note.type == 'note');
                } else {
                    if (note.type == 'note')
                    {
                        if (Math.abs(note.timeDistance) <= missTime)
                            if (keyJustPressed[note.data])
                                if (notesToHit[note.data] == null || note.timeDistance < notesToHit[note.data].timeDistance)
                                    notesToHit[note.data] = note;
                    } else {
                        if (!note.hit && note.timeDistance <= 0 && keyPressed[note.data] && note.parent.hit)
                            hitNote(note, false);

                        if (note.hit && note.clipRect != null && note.clipRect.height <= 0)
                            removeNote(note);
                    }

                    if (note.timeDistance < -missTime && !note.miss)
                        missNote(note);

                    if (note.timeDistance < -despawnTime / scrollSpeed)
                        removeNote(note);
                }
                
                note.followStrum(strum, Conductor.stepCrochet, scrollSpeed);
            }
        );

        for (data in 0...strums.members.length)
        {
            if (notesToHit[data] != null)
            {
                keyJustPressed[data] = false;

                hitNote(notesToHit[data]);

                notesToHit[data] = null;
            }
        }
                                
        strums.forEachAlive(
            (strum) -> {
                if (keyJustPressed[strum.data])
                {
                    keyJustPressed[strum.data] = false;

                    strum.playAnim('pressed');
                }

                if (keyJustReleased[strum.data])
                {
                    keyJustReleased[strum.data] = false;

                    strum.playAnim('idle');
                }
            }
        );
    }

    public function hitNote(note:Note, ?remove:Bool)
    {
        final rating:Rating = judgeNote(note.timeDistance);

        note.hit = true;

        note.character.sing(note.type != 'note' && !note.character.data.sustainAnimation ? null : note.singAnimation);

        if (note.type == 'note' && rating == 'sick' && !botplay)
            splashes.members[note.data].splash();

        strums.members[note.data].playAnim('hit');

        if (remove ?? true)
            removeNote(note);
    }

    public function judgeNote(time:Float):Rating
    {
        time = Math.abs(time);

        if (time < 45)
            return 'sick';

        if (time < 90)
            return 'good';

        if (time < 135)
            return 'bad';

        return 'shit';
    }

    public function missNote(note:Note)
    {
        note.miss = true;

        note.character.sing(note.type != 'note' && !note.character.data.sustainAnimation ? null : note.missAnimation);
    }

    public function removeNote(note:Note)
    {
        note.kill();
        note.exists = false;
        notes.remove(note, false);
    }
}
