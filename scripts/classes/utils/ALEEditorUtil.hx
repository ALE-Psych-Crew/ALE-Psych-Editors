package utils;

import ale.ui.ALENumericStepper;
import ale.ui.ALEUIUtils;

typedef EditorUtilStepper = {
    var label:FlxText;
    var stepper:ALENumericStepper;
};

class ALEEditorUtil
{
    public static function labelStepper(x:Float, y:Float, label:String, initial:Float, min:Float, max:Float, change:Float, instance:String, variable:String, ?callback:Void -> Void)
    {
        var text:FlxText = new FlxText(x, y, 0, label + ': ', 20);
        text.font = ALEUIUtils.FONT;

        var stepper:ALENumericStepper = new ALENumericStepper(text.x + text.width + 10, text.y + text.height / 2, min, max, initial, change);
        stepper.onChange = () -> {
            Reflect.setField(instance, variable, stepper.value);

            if (callback != null)
                callback();
        }
        stepper.y -= stepper.height / 2;

        return {
            label: text,
            stepper: stepper
        }
    }
}