package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

// import core.structures.ALEStrumLine;
// import core.structures.ALESongStrumLine;

import flixel.addons.display.FlxGridOverlay;

import funkin.visuals.editors.ChartNote;

import haxe.ds.GenericStack;

import utils.ALEFormatter;

import ale.ui.ALEMouseSprite;
import ale.ui.ALEUIUtils;

typedef GridNote = {
    var time:Float;
    var data:Int;
    var length:Float;
    var type:String;
}

class ChartGrid extends ScriptSpriteGroup
{
    public var cellSize:Float;

    public var data:ALEStrumLine;

    public var bg:FlxSprite;

    public var notes:FlxTypedSpriteGroup<ChartNote>;

    public var selectedNotes:Array<ChartNote> = [];

    public var pointer:FlxSprite;

    public var sections:Array<Array<GridNote>> = [];

    public function new(config:String, cellSize:Float)
    {
        super();

        Conductor.sectionHit.add(this.updateSection);

        data = ALEFormatter.getStrumLine(config);

        this.cellSize = cellSize;

        pointer = new FlxSprite().makeGraphic(cellSize, cellSize);
        pointer.alpha = 0.25;

        bg = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(cellSize, cellSize, cellSize * data.strums.length, cellSize * Conductor.beatsPerSection * Conductor.stepsPerBeat, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -25), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
        bg.onOverlapChange = (over) -> {
            pointer.visible = over;
        }
        
        bg.onOverlapChange(false);

        add(bg);
        add(pointer);

        add(notes = new FlxTypedSpriteGroup<ChartNote>());

        for (i in 0...Conductor.beatsPerSection)
            add(new FlxSprite(0, i * Conductor.stepsPerBeat * cellSize - 1).makeGraphic(bg.width, 2, 0x40FFFFFF));
    }

    var longNote:Null<ChartNote> = null;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        final mousePos:FlxPoint = FlxG.mouse.getWorldPosition(cameras[0]);

        if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
            for (selected in selectedNotes)
                sections[Conductor.curSection][selected.index].length = selected.length = selected.length + Conductor.stepCrochet * (FlxG.keys.justPressed.Q ? -1 : 1);
        
        if (FlxG.keys.justPressed.DELETE)
            for (selected in selectedNotes.copy())
                removeNote(selected);

        if (Controls.MOUSE_P && !FlxG.mouse.justPressedRight)
            clearSelectedNotes();

        if (pointer.visible)
        {
            pointer.x = CoolUtil.snapNumber(mousePos.x, cellSize);
            pointer.y = CoolUtil.snapNumber(mousePos.y, cellSize);
                
            if (longNote != null)
                if (pointer.y >= longNote.y)
                    sections[Conductor.curSection][longNote.index].length = longNote.length = (pointer.y - longNote.y) / cellSize * Conductor.stepCrochet;

            var overlapedNote:ChartNote = null;

            if (Controls.MOUSE_P || FlxG.mouse.justPressedRight)
            {
                for (note in notes)
                    if (note != null)
                        if (FlxG.mouse.overlaps(note.texture, cameras[0]))
                        {
                            overlapedNote = note;

                            break;
                        }

                if (Controls.MOUSE_P)
                {
                    if (overlapedNote == null)
                    {
                        addNote();
                    } else {
                        removeNote(overlapedNote);
                    }
                }
                
                if (FlxG.mouse.justPressedRight)
                {
                    if (overlapedNote == null)
                    {
                        clearSelectedNotes();
                    } else {
                        if (overlapedNote.selected)
                            deSelectNote(overlapedNote);
                        else
                            selectNote(overlapedNote);
                    }
                }
            }
        }

        if (Controls.MOUSE_R)
        {
            longNote = null;
        }
    }

    override function destroy()
    {
        super.destroy();
        
        Conductor.sectionHit.remove(this.updateSection);
    }

    var notesStack:GenericStack<ChartNote> = new GenericStack<ChartNote>();

    function addNote(?customTime:Int, ?customData:Int, ?customLength:Float, ?customType:String, ?push:Bool):ChartNote
    {
        clearSelectedNotes();

        sections[Conductor.curSection] ??= [];
        
        final time:Float = customTime ?? (CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet) + (pointer.y - y <= 0 ? 0 : ((pointer.y - y) / bg.height * Conductor.stepsPerBeat * Conductor.beatsPerSection * Conductor.stepCrochet)));

        final data:Int = customData ?? Math.floor((pointer.x - x) / cellSize);

        final length:Float = customLength ?? 0;

        final type:String = customType ?? '';

        var note:ChartNote;

        if (notesStack.isEmpty())
            note = new ChartNote(cellSize, this.data);
        else
            note = notesStack.pop();

        note.reset(time, data, length, type);

        @:privateAccess notes.preAdd(note);

        notes.group.members.push(note);

        if (push ?? true)
        {
            note.index = sections[Conductor.curSection].length;

            sections[Conductor.curSection].push({
                time: time,
                data: data,
                length: length,
                type: type
            });

            longNote = note;

            selectNote(note);
        }

        return note;
    }

    function removeNote(note:ChartNote)
    {
        sections[Conductor.curSection][note.index] = null;

        notes.group.members.remove(note);

        notesStack.add(note);

        deSelectNote(note);
    }

    function selectNote(note:ChartNote)
    {
        if (note.selected)
            return;

        selectedNotes.push(note);

        note.selected = true;
    }

    function deSelectNote(note:ChartNote)
    {
        if (!note.selected)
            return;

        selectedNotes.remove(note);

        note.selected = false;
    }

    function clearSelectedNotes()
    {
        for (note in selectedNotes.copy())
            deSelectNote(note);
    }

    public function updateSection(curSection:Float)
    {
        clearSelectedNotes();

        while (notes.members.length > 0)
        {
            var note:ChartNote = notes.members.pop();

            if (note != null)
                notesStack.add(note);
        }

        for (index => note in sections[curSection] ?? [])
            if (note != null)
                addNote(note.time, note.data, note.length, note.type, false).index = index;

        longNote = null;
    }

    override function destroy()
    {
        while (!notesStack.isEmpty())
            notesStack.pop().destroy();

        super.destroy();
    }
}