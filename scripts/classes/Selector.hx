package;

import flixel.util.FlxSpriteUtil;

import openfl.display.BlendMode;

import flixel.FlxObject;

import ale.ui.UIUtils;

class Selector extends scripting.haxe.ScriptedFlxSprite
{
    override function new(?camera:FlxCamera)
    {
        super(600, 200);

        if (camera != null)
            cameras = [camera];

        visible = true;

        makeGraphic(1, 1, UIUtils.COLOR);

        alpha = 0.5;

        blend = BlendMode.ADD;
    }

    public var onSelect:Void -> Void;

    public var selectionCheck:Void -> Bool;

    public var allowSelection:Bool = true;

    public var selecting:Bool = false;

    var mouseOffset:FlxPoint;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (Controls.MOUSE_P && (selectionCheck == null ? true : selectionCheck()) && allowSelection)
        {
            mouseOffset = FlxG.mouse.getWorldPosition(camera);

            selecting = visible = true;
        }

        if (selecting)
        {
            final mousePos = FlxG.mouse.getWorldPosition(camera);

            x = mouseOffset.x;
            y = mouseOffset.y;

            final wantedScales = {
                x: mousePos.x - x,
                y: mousePos.y - y
            }

            scale.x = Math.abs(wantedScales.x);
            scale.y = Math.abs(wantedScales.y);

            if (wantedScales.x < 0)
                x += wantedScales.x;

            if (wantedScales.y < 0)
                y += wantedScales.y;

            updateHitbox();
        }

        if (Controls.MOUSE_R && selecting)
        {
            if (onSelect != null)
                onSelect();

            selecting = visible = false;
        }
    }
}