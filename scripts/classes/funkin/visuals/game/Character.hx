package funkin.visuals.game;

import funkin.visuals.objects.FunkinSprite;

import utils.ALEFormatter;

//import core.structures.ALECharacter;

//import core.enums.CharacterType;

class Character extends FunkinSprite
{
    public var type:CharacterType;

    public function new(initial:String, type:CharacterType)
    {
        super();

        this.type = type;

        change(initial);
    }

    var data:ALECharacter;

    public function change(id:String, ?type:CharacterType)
    {
        if (type != null)
            this.type = type;

        data = ALEFormatter.getCharacter(id);
        
        scale.x = scale.y = data.scale;

        frames = Paths.getMultiAtlas(data.textures);

        flipX = data.flipX != (this.type == 'player');

        antialiasing = data.antialiasing;
        
        for (anim in data.animations)
        {
            if (anim.indices != null && anim.indices.length > 0)
                animation.addByIndices(anim.animation, anim.prefix, anim.indices, '', anim.framerate, anim.loop);
            else
                animation.addByPrefix(anim.animation, anim.prefix, anim.framerate, anim.loop);

            offsets.set(anim.animation, anim.offset);
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

    public function sing(anim:String, ?applyTimer:Bool, ?force:Bool)
    {
        playAnim(anim, force);

        if (applyTimer ?? true)
            danceTimer = data.animationLength / 10;
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