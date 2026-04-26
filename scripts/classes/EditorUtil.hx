package;

import ale.ui.UIUtils;
import ale.ui.Tab;

import flixel.FlxObject;

/**
 * The whole damn game was made using RuleScript
 * @see https://github.com/Kriptel/RuleScript/tree/dev
 * 
 * Thank you for everything, Kriptel
 */

@:unreflective class EditorUtil
{
    // Global

    public static function playSFX(sound:String, ?volume:Float = 0.75, ?pitch:Float = 1):FlxSound
    {
        final sound:FlxSound = FlxG.sound.play(Paths.sound('editors/' + sound), volume);

        sound.pitch = pitch;

        return sound;
    }

    // ALE UI

    public static final UI_MARGIN:Int = 25;

    public static function setToMargin(obj:FlxSprite, ?right:Bool = false, ?down:Bool = false, ?screen:FlxObject)
    {
        obj.x = right ? (screen == null ? FlxG.width : screen.x + screen.width) - obj.width - UI_MARGIN : (screen == null ? 0 : screen.x) + UI_MARGIN;
        obj.y = down ? (screen == null ? FlxG.height : screen.y + screen.height) - obj.height - UI_MARGIN : (screen == null ? 0 : screen.y) + UI_MARGIN;

        if (obj is Tab)
            obj.y += UIUtils.OBJECT_SIZE;
    }

    public static function createLabel(obj:FlxSprite, text:String):FlxText
    {
        final text:FlxText = new FlxText(obj.x, obj.y, 0, text + ': ', 15);
        text.font = UIUtils.FONT;

        obj.y += text.height;

        return text;
    }

    // ChartEditor

    public static final NOTE_SIZE:Int = 50;
}