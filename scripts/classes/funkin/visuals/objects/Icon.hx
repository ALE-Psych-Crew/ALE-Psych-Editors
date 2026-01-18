package funkin.visuals.objects;

import flixel.graphics.FlxGraphic;

import utils.ALEFormatter;

/*
import core.structures.ALEIcon;

import core.enums.CharacterType;
*/

class Icon extends scripting.haxe.ScriptSprite
{
    public var bar:NeoBar;

    public function new(type:CharacterType, ?id:String, ?x:Float, ?y:Float)
    {
        super(x, y);

        change(id, type);
    }

    public var type:CharacterType;

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

    public var id:String;

    public var data:ALEIcon;

    public function change(?id:String, ?type:CharacterType)
    {
        if (type != null)
            this.type = type;

        if (id == null)
            return;

        this.id = id;

        data = ALEFormatter.getIcon(id);

        data.animations.sort((a, b) -> a.percent - b.percent);

        switch (cast data.animationType)
        {
            case 'sheet':
                frames = Paths.getAtlas('icons/' + data.texture);

                for (anim in data.animations)
                    if (anim.indices == null)
                        animation.addByPrefix(anim.animation, anim.prefix, anim.framerate, anim.loop);
                    else
                        animation.addByIndices(anim.animation, anim.prefix, anim.indices, anim.framerate, anim.loop);
            case 'frames':
                final graphic:FlxGraphic = Paths.image('icons/' + data.texture, false, false) ?? Paths.image('icons/face');

                loadGraphic(graphic, true, Math.floor(graphic.width / data.animations.length));

                for (anim in data.animations)
                    animation.add(anim.animation, anim.frames, anim.framerate, anim.loop, anim.flipX);
        }

        flipX = type != 'player' == data.flipX;

        flipY = data.flipY;

        checkAnimation();
    }

    public function bop(curBeat:Int)
    {
        if (data.bopModulo > 0 && curBeat % data.bopModulo == 0)
        {
            scale.x = data.bopScale.x;
            scale.y = data.bopScale.y;

            updateHitbox();
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (data.lerp > 0)
        {
            scale.x = CoolUtil.fpsLerp(scale.x, data.scale.x, data.lerp);
            scale.y = CoolUtil.fpsLerp(scale.y, data.scale.y, data.lerp);

            updateHitbox();
        }

        if (bar != null)
        {
            final isRight:Bool = type == 'player' == bar.rightToLeft;

            final barMiddle:FlxPoint = bar.getMiddle();

            x = isRight ? (barMiddle.x - offsetX) : (barMiddle.x - width + offsetX);
            y = barMiddle.y - height / 2 + offsetY;

            flipX = type != 'player' == data.flipX;
        }

        checkAnimation();
    }

    var animationIndex:Int = -1;

    public function checkAnimation()
    {
        if (bar == null)
            return;

        final percent:Float = type == 'player' ? bar.percent : (100 - bar.percent);

        while (animationIndex + 1 < data.animations.length && percent >= data.animations[animationIndex + 1].percent)
            animationIndex++;

        while (animationIndex >= 0 && percent < data.animations[animationIndex].percent)
            animationIndex--;

        final curAnimation = data.animations[animationIndex].animation;

        if (animation.name != curAnimation)
        {
            animation.play(curAnimation);

            centerOffsets();
        }
    }
}