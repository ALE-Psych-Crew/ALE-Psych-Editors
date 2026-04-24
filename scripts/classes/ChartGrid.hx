package;

// import core.structures.ALESongStrumLine;
// import core.structures.JsonStrumLine;

import flixel.addons.display.FlxGridOverlay;

import ale.ui.MouseSprite;
import ale.ui.UIUtils;

import utils.Formatter;

import Constants;

class ChartGrid extends scripting.haxe.ScriptedFlxSpriteGroup
{
    public var config:JsonStrumLine;

    var grid:MouseSprite;
    var pointer:FlxSprite;

    public function new(config:ALESongStrumLine)
    {
        super(165, 200);

        this.config = Formatter.getStrumLine(config.type);

        grid = new MouseSprite();
        add(grid);

        pointer = new FlxSprite().makeGraphic(Constants.NOTE_SIZE, Constants.NOTE_SIZE);
        add(pointer);
        
        grid.onOverlapChange = (over) -> {
            pointer.visible = over;

            updatePointer();
        };

        grid.onOverlapChange(false);

        regenGrid();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        final pointerData = updatePointer();

        if (pointerData == null)
            return;
    }

    function updatePointer():Null<PointerData>
    {
        if (!pointer.visible)
            return null;

        final mousePos = FlxG.mouse.getScreenPosition(camera);

        pointer.x = CoolUtil.snapNumber(mousePos.x - this.x % Constants.NOTE_SIZE, Constants.NOTE_SIZE);
        pointer.y = CoolUtil.snapNumber(mousePos.y, Constants.NOTE_SIZE);
    }

    function regenGrid()
    {
        grid.pixels = FlxGridOverlay.createGrid(
            Constants.NOTE_SIZE,
            Constants.NOTE_SIZE,
            Constants.NOTE_SIZE * config.config.length,
            Constants.NOTE_SIZE * Conductor.beatsPerSection * Conductor.stepsPerBeat, true,
            UIUtils.adjustColorBrightness(UIUtils.COLOR, -25),
            UIUtils.adjustColorBrightness(UIUtils.COLOR, -60)
        );
    }
}