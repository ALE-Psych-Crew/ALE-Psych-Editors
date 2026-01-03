package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import ale.ui.ALEUIUtils;
import ale.ui.ALEMouseSprite;

import flixel.math.FlxPoint;

import funkin.visuals.editors.ChartNote;

import utils.ALEFormatter;

//import core.structures.ALESongStrumLine;

class ChartGrid extends ScriptSpriteGroup
{
    final NOTE_SIZE:Int;

    final BEATS_PER_SECTION:Int;
    final STEPS_PER_BEAT:Int;
    final STEPS:Int;

    public var background:FlxSprite;

    var notes:FlxTypedSpriteGroup<ChartNote>;

    var pointer:FlxSprite;

    public var animations:Array<String> = [];

    var notePool:Array<ChartNote> = [];

    public final configID:String;

    public final config:ALESongStrumLine;

    public var sections:Array<Array<JSONNote>> = [];

    public function new(noteSize:Int, beats:Int, steps:Int, linePos:Int, ?configFile:String)
    {
        super();

        BEATS_PER_SECTION = beats;

        STEPS_PER_BEAT = steps;

        STEPS = BEATS_PER_SECTION * STEPS_PER_BEAT;

        configID = configFile;

        config = ALEFormatter.getStrumLine(configID);

        NOTE_SIZE = noteSize;

        background = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(NOTE_SIZE, NOTE_SIZE, NOTE_SIZE * config.strums.length, NOTE_SIZE * STEPS, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -75), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
        add(background);
        background.onOverlapChange = (isOver) -> {
            pointer.exists = isOver;
            
            if (longNote != null)
                longNote = null;
        };

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        pointer = new FlxSprite().makeGraphic(NOTE_SIZE, NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        pointer.exists = false;

        var positionLine:FlxSprite = new FlxSprite(0, linePos).makeGraphic(Math.floor(background.width), 5);
        add(positionLine);
        positionLine.scrollFactor.set(1);

        var middleMask:FlxSprite = new FlxSprite(0, background.height).makeGraphic(Math.floor(background.width), Math.floor(background.height));
        middleMask.color = FlxColor.BLACK;
        middleMask.alpha = 0.5;
        add(middleMask);
    }

    var _lastSec:Int = -1;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (_lastSec != Conductor.curSection)
        {
            _lastSec = Conductor.curSection;

            updateSection(_lastSec);
        }

        if (pointer.exists)
        {
            pointer.x = x + Math.floor((mousePos.x - x) / NOTE_SIZE) * NOTE_SIZE;
            pointer.y = y + Math.floor((mousePos.y - y) / NOTE_SIZE) * NOTE_SIZE;

            pointer.color = Controls.MOUSE_P || FlxG.mouse.justPressedRight ? FlxColor.GRAY : FlxColor.WHITE;

            if (longNote != null)
            {
                if (pointer.y >= longNote.y)
                {
                    longNote.length = (pointer.y - longNote.y) / NOTE_SIZE * Conductor.stepCrochet;
                    
                    sections[Conductor.curSection][longNote.index].length = longNote.length;
                }
            }

            if (Controls.MOUSE_P || FlxG.mouse.justPressedRight)
            {
                var overlapedNote:ChartNote = null;
                
                for (note in notes)
                {
                    if (!note.alive)
                        continue;

                    if (FlxG.mouse.overlaps(note.texture))
                    {
                        overlapedNote = note;

                        break;
                    }
                }

                if (Controls.MOUSE_P)
                {
                    if (overlapedNote == null)
                        addNote();
                    else
                        removeNote(overlapedNote);
                } else {
                    if (overlapedNote != null)
                        if (overlapedNote.selected)
                            deSelectNote(overlapedNote);
                        else
                            selectNote(overlapedNote);
                }
            }
        }
        
        if (Controls.MOUSE_P)
            for (note in selected)
                if (note != null)
                    deSelectNote(note);

        if (Controls.MOUSE_R)
        {
            if (longNote != null)
            {
                selectNote(longNote);

                longNote = null;
            }
        }

        if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
            for (note in selected)
                if (note != null)
                    note.length = Math.max(0, note.length + Conductor.stepCrochet * (FlxG.keys.justPressed.Q ? -1 : 1));

        if (FlxG.keys.justPressed.DELETE)
            for (note in selected)
                if (note != null)
                    removeNote(note);
    }

    var mousePos(get, never):FlxPoint;
    function get_mousePos():FlxPoint
    {
        return FlxG.mouse.getWorldPosition(cameras[0]);
    }

    var selected:Array<Null<ChartNote>> = [];

    var longNote:Null<ChartNote> = null;

    function addNote(?customData:Int, ?customTime:Float, ?length:Float, ?type:String, ?push:Bool)
    {
        sections[Conductor.curSection] ??= [];

        final data:Int = customData ?? Math.floor((pointer.x - x) / NOTE_SIZE);

        final strumConfig:ALESongStrum = config.strums[data];

        final time:Float = customTime ?? (pointer.y - y <= 0 ? 0 : (pointer.y - y) / background.height * STEPS * Conductor.stepCrochet);

        final anim:String = strumConfig.note;

        final length:Float = length ?? 0;

        final type:String = type ?? '';

        var note:ChartNote;
        
        if (notePool.length <= 0)
            note = new ChartNote(config.textures, NOTE_SIZE);
        else
            note = notePool.pop();

        note.reset(anim, data, time, length, type, strumConfig.shader);

        note.index = sections[Conductor.curSection].length;

        @:privateAccess notes.preAdd(note);
        notes.group.members.push(note);

        if (push ?? true)
        {
            sections[Conductor.curSection].push(
                {
                    time: time,
                    data: data,
                    length: length,
                    type: type
                }
            );

            longNote = note;
        }
    }

    function removeNote(note:ChartNote)
    {
        if (note.selected)
            deSelectNote(note);

        sections[Conductor.curSection][note.index] = null;

        notes.group.members.remove(note);

        notePool.push(note);
    }

    function selectNote(note:ChartNote)
    {
        note.selected = true;

        note.selectedIndex = selected.length;

        selected.push(note);
    }

    function deSelectNote(note:ChartNote)
    {
        note.selected = false;

        selected[note.selectedIndex] = null;

        note.selectedIndex = null;
    }

    function updateSection(curSection:Int)
    {
        longNote = null;

        selected.resize(0);

        for (note in notes)
        {
            notePool.push(note);

            notes.members.remove(note, true);
        }

        var jsonSection:Array<JSONNote> = sections[curSection];

        jsonSection ??= [];

        for (note in jsonSection)
            if (note != null)
                addNote(note.data, note.time, note.length, note.type, false);
    }

    override function destroy()
    {
        for (note in notePool)
        {
            note.destroy();

            note = null;
        }

        super.destroy();
    }
}