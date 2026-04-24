package;

import ale.ui.UIUtils;
import ale.ui.Tab;

/**
 * The whole damn game was made using RuleScript
 * @see https://github.com/Kriptel/RuleScript/tree/dev
 * 
 * Thank you for everything, Kriptel
 */

@:unreflective class EditorUtil
{
    public static final UI_MARGIN:Int = 25;

    public static function setToMargin(obj:Dynamic, ?right:Bool = false, ?down:Bool = false)
    {
        obj.x = right ? FlxG.width - obj.width - UI_MARGIN : UI_MARGIN;
        obj.y = down ? FlxG.height - obj.height - UI_MARGIN : UI_MARGIN;

        if (obj is Tab)
            obj.y += UIUtils.OBJECT_SIZE;
    }

    // ChartEditor

    public static final NOTE_SIZE:Int = 50;
}