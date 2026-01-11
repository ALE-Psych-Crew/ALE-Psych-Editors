package funkin.visuals.game;

import utils.ALEFormatter;

import funkin.visuals.game.Strum;
import funkin.visuals.game.ALENote;

import flixel.input.keyboard.FlxKey;

import core.enums.CharacterType;

//import core.structures.ALEStrumLine;
//import core.structures.ALESongStrumLine;

//import core.enums.CharacterType;

class StrumLine extends scripting.haxe.ScriptSpriteGroup
{
    public var strums:FlxTypedSpriteGroup<Strum>;
    public var notes:FlxTypedSpriteGroup<Note>;
    public var splashes:FlxTypedSpriteGroup<Splas>;

    public var botplay:Bool;

    public var notesToSpawn:Array<Note> = [];

    public final config:ALEStrumLine;

    public var scrollSpeed:Float = 1;

    public function new(chartData:ALESongStrumLine, arrayNotes:Array<Dynamic>, speed:Float)
    {
        super();

        this.scrollSpeed = speed;

        config = ALEFormatter.getStrumLine(chartData.file);

        visible = chartData.visible;

        botplay = chartData.type != 'player';

        add(strums = new FlxTypedSpriteGroup<Strum>());

        var inputs = ClientPrefs.controls.notes;

        var inputsArray = [inputs.left, inputs.down, inputs.up, inputs.right];

        var strumHeight:Int = 0;

        for (strumIndex => strumConfig in config.strums)
        {
            final strum:Strum = new Strum(strumConfig, strumIndex, inputsArray[strumIndex], config.textures, config.scale, config.space);
            strums.add(strum);
            strum.returnToIdle = botplay;

            strumHeight = Math.max(strumHeight, strum.height);
        }

        x = chartData.rightToLeft ? config.position.x : FlxG.width - config.position.x - (config.strums.length - 1) * config.space - strums.members[strums.members.length - 1].width;
        y = ClientPrefs.data.downScroll ? FlxG.height - config.position.y - strumHeight : config.position.y;
        
        add(notes = new FlxTypedSpriteGroup<Note>());

        for (note in arrayNotes)
            notesToSpawn.unshift(new ALENote(config.strums[note[1]], strums.members[note[1]], note[0], note[1], note[2], note[3], 'note', config.space, config.scale, config.textures));
    }

    public var spawnTime:Float = 3000;

    public var missTime:Float = 175;

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        while (notesToSpawn.length > 0 && notesToSpawn[notesToSpawn.length - 1].time <= Conductor.songPosition + spawnTime)
            notes.add(notesToSpawn.pop());

        for (note in notes)
        {
            var timeDiff:Float = note.time - Conductor.songPosition;

            note.y = this.y + timeDiff * (ClientPrefs.data.downScroll ? -0.45 : 0.45) * scrollSpeed;

            if (timeDiff <= 0)
            {
                if (botplay)
                    hitNote(note);
                else if (!note.isOnScreen())
                    removeNote(note);
            }
        }

        if (botplay)
            return;

        for (strum in strums)
        {
            if (FlxG.keys.anyJustPressed(strum.input))
                strum.playAnim('pressed');

            if (FlxG.keys.anyJustReleased(strum.input))
                strum.playAnim('idle');
        }
    }

    public function hitNote(note:ALENote)
    {
        note.strum.playAnim('hit');

        removeNote(note);
    }

    public function removeNote(note:ALENote)
    {
        notes.remove(note, true);
    }
}