package;

// import core.structures.ALESongStrumLine;
// import core.structures.JsonStrumLine;

import flixel.addons.display.FlxGridOverlay;

import ale.ui.MouseSprite;
import ale.ui.UIUtils;

import utils.Formatter;

import EditorUtil;

class ChartGrid extends scripting.haxe.ScriptedFlxSpriteGroup
{
    public var config:JsonStrumLine;

    public var grid:MouseSprite;
    var pointer:FlxSprite;

    public function new(config:ALESongStrumLine)
    {
        super();

        this.config = Formatter.getStrumLine(config.type);

        grid = new MouseSprite();
        add(grid);

        pointer = new FlxSprite().makeGraphic(EditorUtil.NOTE_SIZE, EditorUtil.NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        
        grid.onOverlapChange = (over) -> {
            pointer.visible = over;

            updatePointer();
        };

        grid.onOverlapChange(false);

        regenGrid();

        Conductor.sectionHit.add(onSectionHit);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        final pointerData = updatePointer();

        if (pointerData == null)
            return;
    }

    override function destroy()
    {
        super.destroy();

        Conductor.sectionHit.remove(onSectionHit);
    }

    function onSectionHit(curSection:Int)
    {
        regenGrid();
    }

    function updatePointer():Null<PointerData>
    {
        if (!pointer.visible)
            return null;

        final mousePos = FlxG.mouse.getWorldPosition(camera);

        pointer.x = x + CoolUtil.snapNumber(mousePos.x - x, EditorUtil.NOTE_SIZE);
        pointer.y = y + CoolUtil.snapNumber(mousePos.y - y, EditorUtil.NOTE_SIZE);
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
}