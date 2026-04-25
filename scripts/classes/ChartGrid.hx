package;

// import core.structures.ALESongStrumLine;
// import core.structures.JsonStrumLine;

import flixel.addons.display.FlxGridOverlay;

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

    public function new(data:ALESongStrumLine)
    {
        Conductor.sectionHit.add(onSectionHit);
     
        super();

        this.config = Formatter.getStrumLine(data.type);

        grid = new MouseSprite();
        grid.antialiasing = false;
        add(grid);

        pointer = new FlxSprite().makeGraphic(EditorUtil.NOTE_SIZE, EditorUtil.NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        
        grid.onOverlapChange = (over) -> {
            pointer.visible = over;

            updatePointer();
        };

        grid.onOverlapChange(false);

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        regenGrid();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        final pointerData = updatePointer();

        if (!pointerData)
            return;

        if (Controls.MOUSE_P)
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
                addNote();
            } else {
                removeNote(overlapedNote);
            }
        }
    }

    function updatePointer():Bool
    {
        if (!pointer.visible)
            return false;

        final mousePos = FlxG.mouse.getWorldPosition(camera);

        pointer.x = x + CoolUtil.snapNumber(mousePos.x - x, EditorUtil.NOTE_SIZE);
        pointer.y = y + CoolUtil.snapNumber(mousePos.y - y, EditorUtil.NOTE_SIZE);

        return true;
    }

    function onSectionHit(curSection:Int)
    {
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
        final note:ChartNote = notePool.isEmpty() ? new ChartNote(config.notes, config.config) : notePool.pop();
        note.time = time ?? CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet) + (pointer.y - y <= 0 ? 0 : ((pointer.y - y) / grid.height * Conductor.stepsPerBeat * Conductor.beatsPerSection * Conductor.stepCrochet));
        note.data = data ?? Math.floor((pointer.x - x) / EditorUtil.NOTE_SIZE);
        note.length = length ?? 0;
        note.type = type ?? '';

        sections[Conductor.curSection] ??= [];

        note.index = sections[Conductor.curSection].length;

        if (push)
            sections[Conductor.curSection].push({
                time: note.time,
                data: note.data,
                length: note.length,
                type: note.type
            });

        notes.add(note);

        return note;
    }

    function removeNote(note:ChartNote, ?delete:Bool = true)
    {
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

    override function destroy()
    {
        while (!notePool.isEmpty())
            notePool.pop().destroy();

        super.destroy();

        Conductor.sectionHit.remove(onSectionHit);
    }
}