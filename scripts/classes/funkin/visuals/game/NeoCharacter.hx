package funkin.visuals.game;

import funkin.visuals.objects.FunkinSprite;

import utils.ALEFormatter;

/*
import core.structures.ALECharacter;

import core.enums.CharacterType;
*/

class NeoCharacter extends FunkinSprite
{
    public var type:CharacterType;

    public function new(initial:String, type:CharacterType)
    {
        super();

        this.type = type;

        change(initial);

        anim.onFinish.add((name) -> {
            if (offsets.exists(name + '-loop'))
                playAnim(name + '-loop');
        });
    }

    public var data:ALECharacter;

    public var id:String;

    public function change(id:String, ?type:CharacterType)
    {
        if (type != null)
            this.type = type;

        final jsonData:ALECharacter = ALEFormatter.getCharacter(id, this.type);

        if (jsonData == null)
            return;

        this.id = id;

        data = jsonData;
        
        scale.x = scale.y = data.scale;

        flipX = data.flipX != (this.type == 'player');

        flipY = data.flipY;

        antialiasing = data.antialiasing;

        offsets.clear();

        loadFrames(cast data.type, data.textures, data.animations.length);

        for (animData in data.animations)
        {
            addAnimation(cast data.type, animData.name, animData.prefix, animData.framerate, animData.loop, animData.indices);

            offsets.set(animData.name, animData.offset);
        }

        if (offsets.exists('danceLeft') && offsets.exists('danceRight'))
            playAnim('danceLeft');
        else
            playAnim('idle');

        updateHitbox();
    }

    public var danceTimer:Float = 0;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (danceTimer > 0)
            danceTimer -= elapsed;
    }

    public function sing(?anim:String, ?applyTimer:Bool, ?force:Bool)
    {
        if (anim != null)
            playAnim(anim, force);

        if (applyTimer ?? true)
            danceTimer = data.animationLength;
    }

    public function dance()
    {
        if (Conductor.curBeat % data.danceModulo == 0 && danceTimer <= 0)
            if (offsets.exists('danceLeft') && offsets.exists('danceRight'))
                playAnim(Conductor.curBeat % (data.danceModulo * 2) == 0 ? 'danceLeft' : 'danceRight');
            else
                playAnim('idle');
    }
}