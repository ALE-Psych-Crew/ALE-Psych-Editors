package funkin.visuals.objects;

import haxe.ds.StringMap;

// import core.structures.Point;

class FunkinSprite extends scripting.haxe.ScriptSprite
{
    public var offsets:StringMap<Point> = new StringMap();

    public function playAnim(anim:String, ?force:Bool)
    {
        animation.play(anim, force ?? true);

        final animOffset:Point = offsets.get(anim) ?? {
            x: 0,
            y: 0
        };

        offset.set(animOffset.x, animOffset.y);
    }
}