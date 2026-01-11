package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import ale.ui.ALEUIUtils;
import ale.ui.ALEMouseSprite;
import ale.ui.ALEDropDownMenu;

import flixel.math.FlxPoint;

import funkin.visuals.editors.ChartNote;

import utils.ALEFormatter;

import funkin.visuals.objects.HealthIcon;

//import core.structures.ALESongStrumLine;
//import core.structures.GridNote;

class ChartGrid extends ScriptSpriteGroup
{
    final CHARTING_STATE:MusicBeatState = MusicBeatState.instance;
    
    final NOTE_SIZE:Int;

    final STEPS:Int;

    final CHARACTERS_MAP:StringMap<String> = new StringMap();

    public var background:FlxSprite;

    var notes:FlxTypedSpriteGroup<ChartNote>;

    var pointer:FlxSprite;

    public var animations:Array<String> = [];

    var notePool:Array<ChartNote> = [];

    public final configID:String;

    public final config:ALESongStrumLine;

    public var sections:Array<Array<GridNote>> = [];

    public var icon:HealthIcon;

    public var characterDropdown:ALEDropDownMenu;

    public var character:Null<String>;

    public var charIndex:Int = 0;

    final NONE_CHARACTER:String = '< None >';

    public function new(charactersMap:Array<String>, noteSize:Int, linePos:Int, ?configFile:String)
    {
        super();

        STEPS = Conductor.stepsPerBeat * Conductor.beatsPerSection;

        config = ALEFormatter.getStrumLine(configFile);

        NOTE_SIZE = noteSize;

        background = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(NOTE_SIZE, NOTE_SIZE, NOTE_SIZE * config.strums.length, NOTE_SIZE * STEPS, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -75), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
        add(background);
        background.onOverlapChange = (isOver) -> {
            pointer.exists = isOver;
            
            if (longNote != null)
                longNote = null;
        };

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        pointer = new FlxSprite().makeGraphic(NOTE_SIZE, NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        pointer.exists = false;

        var positionLine:FlxSprite = new FlxSprite(0, linePos).makeGraphic(Math.floor(background.width), 5);
        add(positionLine);
        positionLine.scrollFactor.set(1);

        CHARACTERS_MAP = charactersMap;

        icon = new HealthIcon('face');
        add(icon);

        characterDropdown = new ALEDropDownMenu(0, -50, [NONE_CHARACTER].concat([for (key in CHARACTERS_MAP.keys()) key]), background.width - ALEUIUtils.OBJECT_SIZE);
        add(characterDropdown);
        characterDropdown.selectionCallback = setCharacter;

        setCharacter(NONE_CHARACTER);
    }

    public function setCharacter(char:String)
    {
        character = char == NONE_CHARACTER ? null : char;

        icon.changeIcon(CHARACTERS_MAP.get(character));
        icon.scale.set(1, 1);
        icon.updateHitbox();

        var factor:Float = Math.min(background.width / 2 / icon.width, background.width / 2 / icon.height);

        icon.scale.x = icon.scale.y = factor;
        icon.updateHitbox();
        icon.centerOrigin();

        icon.x = this.x + background.width / 2 - icon.width / 1.5;
        icon.y = this.y - 125 - icon.height / 2;
        icon.alpha = 0.5;

        characterDropdown.bg.value = char;
    }

    var _lastSec:Int = -1;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (_lastSec != Conductor.curSection)
        {
            _lastSec = Conductor.curSection;
            
            updateSection(_lastSec);
        }

        if (characterDropdown.open)
        {
            pointer.visible = false;

            return;
        } else {
            pointer.visible = true;
        }

        if (pointer.exists)
        {
            pointer.x = x + Math.floor((mousePos.x - x) / NOTE_SIZE) * NOTE_SIZE;
            pointer.y = y + Math.floor((mousePos.y - y) / NOTE_SIZE) * NOTE_SIZE;

            pointer.color = Controls.MOUSE_P || FlxG.mouse.justPressedRight ? FlxColor.GRAY : FlxColor.WHITE;

            if (longNote != null)
            {
                if (pointer.y >= longNote.y)
                {
                    longNote.length = (pointer.y - longNote.y) / NOTE_SIZE * Conductor.stepCrochet;
                    
                    sections[Conductor.curSection][longNote.index].length = longNote.length;
                }
            }

            if (Controls.MOUSE_P || FlxG.mouse.justPressedRight)
            {
                var overlapedNote:ChartNote = null;
                
                for (note in notes)
                {
                    if (!note.alive)
                        continue;

                    if (FlxG.mouse.overlaps(note.texture))
                    {
                        overlapedNote = note;

                        break;
                    }
                }

                if (Controls.MOUSE_P)
                {
                    if (overlapedNote == null)
                        addNote();
                    else
                        removeNote(overlapedNote);
                } else {
                    if (overlapedNote != null)
                        if (overlapedNote.selected)
                            deSelectNote(overlapedNote);
                        else
                            selectNote(overlapedNote);
                }
            }
        }
        
        if (Controls.MOUSE_P)
            for (note in selected)
                if (note != null)
                    deSelectNote(note);

        if (Controls.MOUSE_R)
        {
            if (longNote != null)
            {
                selectNote(longNote);

                longNote = null;
            }
        }

        if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
            for (note in selected)
                if (note != null)
                    note.length = Math.max(0, note.length + Conductor.stepCrochet * (FlxG.keys.justPressed.Q ? -1 : 1));

        if (FlxG.keys.justPressed.DELETE)
            for (note in selected)
                if (note != null)
                    removeNote(note);
    }

    var mousePos(get, never):FlxPoint;
    function get_mousePos():FlxPoint
    {
        return FlxG.mouse.getWorldPosition(cameras[0]);
    }

    var selected:Array<Null<ChartNote>> = [];

    var longNote:Null<ChartNote> = null;

    function addNote(?customData:Int, ?customTime:Float, ?length:Float, ?type:String, ?push:Bool):ChartNote
    {
        sections[Conductor.curSection] ??= [];

        final data:Int = customData ?? Math.floor((pointer.x - x) / NOTE_SIZE);

        final strumConfig:ALESongStrum = config.strums[data];

        final time:Float = customTime ?? (CoolUtil.snapNumber(Conductor.songPosition - CHARTING_STATE.bpmChangeMap[CHARTING_STATE.curBPMIndex].time, Conductor.sectionCrochet) + (pointer.y - y <= 0 ? 0 : ((pointer.y - y) / background.height * STEPS * Conductor.stepCrochet)));

        final anim:String = strumConfig.note;

        final length:Float = length ?? 0;

        final type:String = type ?? '';

        var note:ChartNote;
        
        if (notePool.length <= 0)
            note = new ChartNote(config.textures, NOTE_SIZE);
        else
            note = notePool.pop();

        note.reset(anim, data, time, length, type, strumConfig.shader);

        note.index = sections[Conductor.curSection].length;

        @:privateAccess notes.preAdd(note);
        notes.group.members.push(note);

        if (push ?? true)
        {
            sections[Conductor.curSection].push(
                {
                    time: time,
                    data: data,
                    length: length,
                    type: type
                }
            );

            longNote = note;
        }

        return note;
    }

    function removeNote(note:ChartNote)
    {
        if (note.selected)
            deSelectNote(note);

        sections[Conductor.curSection][note.index] = null;

        debugTrace(sections[Conductor.curSection]);

        notes.group.members.remove(note);

        notePool.push(note);
    }

    function selectNote(note:ChartNote)
    {
        note.selected = true;

        note.selectedIndex = selected.length;

        selected.push(note);
    }

    function deSelectNote(note:ChartNote)
    {
        note.selected = false;

        selected[note.selectedIndex] = null;

        note.selectedIndex = null;
    }

    function updateSection(curSection:Int)
    {
        longNote = null;

        selected.resize(0);

        while (notes.members.length > 0)
        {
            var n = notes.members.pop();

            if (n != null)
                notePool.push(n);
        }

        var jsonSection:Array<JSONNote> = sections[curSection];

        jsonSection ??= [];

        for (index => note in jsonSection)
            if (note != null)
                addNote(note.data, note.time, note.length, note.type, false).index = index;
    }

    override function destroy()
    {
        for (note in notePool)
        {
            note.destroy();

            note = null;
        }

        super.destroy();
    }
}