package;

// import core.structures.ALESongStrumLine;
// import core.structures.JsonStrumLine;

import flixel.addons.display.FlxGridOverlay;
import flixel.input.keyboard.FlxKey;

import haxe.ds.GenericStack;

import ale.ui.MouseSprite;
import ale.ui.UIUtils;

import utils.Formatter;

import EditorUtil;

typedef GridNote = {
    var time:Float;
    var data:Int;
    var length:Float;
    var type:String;
};

class ChartGrid extends scripting.haxe.ScriptedFlxSpriteGroup
{
    public var config:JsonStrumLine;

    public var grid:MouseSprite;
    var pointer:FlxSprite;

    public var notes:FlxTypedSpriteGroup<ChartNote>;

    public var sections:Array<Array<GridNote>> = [];

    public var sustain:ChartNote;

    public function new(data:ALESongStrumLine)
    {
        Conductor.sectionHit.add(onSectionHit);
     
        super();

        this.config = Formatter.getStrumLine(data.type);

        grid = new MouseSprite();
        grid.antialiasing = false;
        add(grid);

        pointer = new FlxSprite().makeGraphic(EditorUtil.NOTE_SIZE, EditorUtil.NOTE_SIZE);
        pointer.antialiasing = false;
        pointer.alpha = 0.25;
        add(pointer);
        
        grid.onOverlapChange = (over) -> {
            pointer.visible = over;
        };

        grid.onOverlapChange(false);

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        regenGrid();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (Controls.anyJustPressed([FlxKey.Q, FlxKey.E]))
            for (note in notes)
                if (note.selected)
                    sections[Conductor.curSection][note.index].length = note.length = note.length + Conductor.stepCrochet * (Controls.anyJustPressed([FlxKey.Q]) ? -1 : 1);

        if (Controls.anyJustPressed([FlxKey.DELETE]))
        {
            var playedSound:Bool = false;

            for (note in notes.members.copy())
            {
                if (note.selected)
                {
                    removeNote(note);

                    if (!playedSound)
                    {
                        playedSound = true;

                        EditorUtil.playSFX('noteErase');
                    }
                }
            }
        }

        if (sustain != null)
            if (pointer.y >= sustain.y)
                    sections[Conductor.curSection][sustain.index].length = sustain.length = (pointer.y - sustain.y) / EditorUtil.NOTE_SIZE * Conductor.stepCrochet;

        if (Controls.MOUSE_R)
        {
            sustain = null;
        }

        if (!pointer.visible)
        {
            if (Controls.MOUSE_P)
                deSelectNotes();

            return;
        }

        final mousePos = FlxG.mouse.getWorldPosition(camera);

        pointer.x = x + CoolUtil.snapNumber(mousePos.x - x, EditorUtil.NOTE_SIZE);
        pointer.y = y + CoolUtil.snapNumber(mousePos.y - y, EditorUtil.NOTE_SIZE);

        if (Controls.MOUSE_P || FlxG.mouse.justPressedRight)
        {
            var overlapedNote:ChartNote;

            for (note in notes)
            {
                if (FlxG.mouse.overlaps(note.note))
                {
                    overlapedNote = note;

                    break;
                }
            }

            if (overlapedNote == null)
            {
                if (Controls.MOUSE_P)
                {
                    addNote();

                    EditorUtil.playSFX('noteLay', 0.25);
                }
            } else {
                if (Controls.MOUSE_P)
                {
                    removeNote(overlapedNote);

                    EditorUtil.playSFX('noteLay', 0.25, 0.5);
                } else {
                    overlapedNote.selected = !overlapedNote.selected;
                }
            }
        }
    }

    function onSectionHit(curSection:Int)
    {
        deSelectNotes();

        clearSectionNotes();

        createSectionNotes();

        regenGrid();
    }

    var prevBeatsPerSection:Int = -1;
    var prevStepsPerBeat:Int = -1;

    function regenGrid()
    {
        if (prevStepsPerBeat == Conductor.stepsPerBeat && prevBeatsPerSection == Conductor.beatsPerSection)
            return;

        prevStepsPerBeat = Conductor.stepsPerBeat;
        prevBeatsPerSection = Conductor.beatsPerSection;

        grid.pixels = FlxGridOverlay.createGrid(
            EditorUtil.NOTE_SIZE,
            EditorUtil.NOTE_SIZE,
            EditorUtil.NOTE_SIZE * config.config.length,
            EditorUtil.NOTE_SIZE * Conductor.beatsPerSection * Conductor.stepsPerBeat, true,
            UIUtils.adjustColorBrightness(UIUtils.COLOR, -25),
            UIUtils.adjustColorBrightness(UIUtils.COLOR, -60)
        );
    }

    var notePool:GenericStack<ChartNote> = new GenericStack<ChartNote>();

    function addNote(?time:Float, ?data:Int, ?length:Float, ?type:String, ?push:Bool = true):ChartNote
    {
        deSelectNotes();

        final note:ChartNote = notePool.isEmpty() ? new ChartNote(config.notes, config.config) : notePool.pop();
        note.time = time ?? CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet) + (pointer.y - y <= 0 ? 0 : ((pointer.y - y) / grid.height * Conductor.stepsPerBeat * Conductor.beatsPerSection * Conductor.stepCrochet));
        note.data = data ?? Math.floor((pointer.x - x) / EditorUtil.NOTE_SIZE);
        note.length = length ?? 0;
        note.type = type ?? '';

        sections[Conductor.curSection] ??= [];

        note.index = sections[Conductor.curSection].length;

        if (push)
        {
            sections[Conductor.curSection].push({
                time: note.time,
                data: note.data,
                length: note.length,
                type: note.type
            });

            sustain = note;

            note.selected = true;
        }

        notes.add(note);

        return note;
    }

    function removeNote(note:ChartNote, ?delete:Bool = true)
    {
        note.hit = note.selected = false;

        if (delete)
            sections[Conductor.curSection][note.index] = null;

        notes.remove(note, true);

        notePool.add(note);
    }

    function clearSectionNotes(?delete:Bool = false)
    {
        for (note in notes.members.copy())
            removeNote(note, delete);
    }

    function createSectionNotes()
    {
        sections[Conductor.curSection] ??= [];

        for (index => note in sections[Conductor.curSection])
            if (note != null)
                addNote(note.time, note.data, note.length, note.type, false).index = index;
    }

    function deSelectNotes()
    {
        for (note in notes)
            note.selected = false;
    }

    override function destroy()
    {
        while (!notePool.isEmpty())
            notePool.pop().destroy();

        super.destroy();

        Conductor.sectionHit.remove(onSectionHit);
    }
}