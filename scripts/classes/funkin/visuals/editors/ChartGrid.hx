package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import ale.ui.ALEUIUtils;
import ale.ui.ALEMouseSprite;

import flixel.math.FlxPoint;

class ChartGrid extends ScriptSpriteGroup
{
    final NOTE_SIZE:Int;

    var background:FlxSprite;

    var notes:FlxTypedGroup<ChartNote>;

    var pointer:FlxSprite;

    public function new(noteSize:Int, strums:Int, length:Int, linePos:Int)
    {
        super();

        NOTE_SIZE = noteSize;

        background = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(NOTE_SIZE, NOTE_SIZE, NOTE_SIZE * strums, NOTE_SIZE * length, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -75), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
        add(background);
        background.onOverlapChange = (isOver) -> {
            pointer.exists = isOver;
            
            pointer.color = FlxColor.WHITE;
        };

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        pointer = new FlxSprite().makeGraphic(NOTE_SIZE, NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        pointer.exists = false;

        var positionLine:FlxSprite = new FlxSprite(0, linePos).makeGraphic(Math.floor(background.width), 5);
        add(positionLine);
        positionLine.scrollFactor.set();

        var middleMask:FlxSprite = new FlxSprite(0, background.height / 2).makeGraphic(Math.floor(background.width), Math.floor(background.height / 2));
        middleMask.color = FlxColor.BLACK;
        middleMask.alpha = 0.5;
        add(middleMask);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        updatePointer();
    }

    var mousePos(get, never):FlxPoint;
    function get_mousePos():FlxPoint
    {
        return FlxG.mouse.getWorldPosition(cameras[0]);
    }

    function updatePointer()
    {
        if (!pointer.exists)
            return;

        if (FlxG.mouse.justPressed)
            pointer.color = FlxColor.GRAY;

        if (FlxG.mouse.justReleased)
            pointer.color = FlxColor.WHITE;

        pointer.x = x + Math.floor(mousePos.x / NOTE_SIZE) * NOTE_SIZE;
        pointer.y = y + Math.floor(mousePos.y / NOTE_SIZE) * NOTE_SIZE;
    }
}