package utils;

/*
import core.structures.ALESong;
import core.structures.ALESongSection;
import core.structures.ALEStrumLine;
import core.structures.PsychSong;
import core.structures.PsychSongSection;
import core.structures.ALECharacter;

import core.enums.CharacterType;
*/

import utils.cool.FileUtil;

using StringTools;

class ALEFormatter
{
    public static final CHART_FORMAT:String = 'ale-chart-v0.1';

    public static function getSong(name:String, difficulty:String):ALESong
    {
        final path:String = 'songs/' + name + '/charts/' + difficulty + '.json';

        final complexPath:String = FileUtil.searchComplexFile(path);

        var json:Dynamic = Paths.json(complexPath.substring(0, path.length - 5));

        var result:ALESong = null;

        if (json.format == CHART_FORMAT)
            result = cast json;

        if (result == null)
        {
            var psychSong:PsychSong = getPsychSong(json);
   
            result = {
                strumLines: [
                    for (i in 0...3)
                    {
                        {
                            file: 'default',
                            position: {
                                x: 92,
                                y: 50
                            },
                            rightToLeft: i == 1,
                            visible: i != 0,
                            characters: [[psychSong.gfVersion, psychSong.player2, psychSong.player1][i]],
                            type: cast ['extra', 'opponent', 'player'][i]
                        }
                    }
                ],
                sections: [],
                speed: psychSong.speed,
                bpm: psychSong.bpm,
                format: CHART_FORMAT,
                stepsPerBeat: 4,
                beatsPerSection: 4
            };

            for (section in psychSong.notes)
            {
                var curSection:ALESongSection = {
                    notes: [],
                    camera: [section.gfSection ? 2 : section.mustHitSection ? 1 : 0, 0],
                    bpm: section.changeBPM == true ? section.bpm : psychSong.bpm,
                    changeBPM: section.changeBPM ?? false
                };

                if (section.sectionNotes != null)
                {
                    for (note in section.sectionNotes)
                    {
                        var arrayNote:Array<Dynamic> = [
                            note[0],
                            note[1] % 4,
                            note[2],
                            note[3] == 'GF Sing' && section.gfSection && note[1] < 4 ? '' : (note[3] ?? ''),
                            [note[3] == 'GF Sing' || section.gfSection && note[1] < 4 ? 0 : (section.mustHitSection && note[1] < 4) || (!section.mustHitSection && note[1] > 3) ? 2 : 1, 0]
                        ];

                        curSection.notes.push(arrayNote);
                    }
                }

                result.sections.push(curSection);
            }
        }

        for (section in result.sections)
        {
            section.notes.sort((a, b) -> {
                return (a[0] < b[0]) ? 1 : (a[0] > b[0]) ? -1 : 0;
            });
        }

        return result;
    }

    public static function getPsychSong(json:Dynamic):PsychSong
    {
		if (json.format == 'psych_v1_convert' || json.format == 'psych_v1')
		{
			for (section in cast(json.notes, Array<Dynamic>))
				if (section.sectionNotes != null && section.sectionNotes.length > 0)
					for (note in cast(section.sectionNotes, Array<Dynamic>))
						if (!section.mustHitSection)
							note[1] = note[1] > 3 ? note[1] % 4 : note[1] += 4;
		} else {
			json = json.song;
		}

		if (json.gfVersion == null)
		{
			json.gfVersion = json.player3;

			json.player3 = null;
		}

		if (json.events == null)
		{
			json.events = [];
			
			for (secNum in 0...json.notes.length)
			{
				var sec:PsychSongSection = json.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;

				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];

					if (note[1] < 0)
					{
						json.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}

					else i++;
				}
			}
		}

		return cast json;
    }
    
    public static final CHARACTER_FORMAT:String = 'ale-character-v0.1';

    public static function getCharacter(char:String):ALECharacter
    {
        var json:Dynamic = Paths.json('characters/' + char);

        if (json.format == CHARACTER_FORMAT)
            return cast json;

        var psychJson:PsychCharacter = cast json;

        var result:ALECharacter = {
            animations: [],
            scale: psychJson.scale,
            animationLength: psychJson.sing_duration,
            icon: psychJson.healthicon,
            position: {
                x: psychJson.position[0],
                y: psychJson.position[1]
            },
            cameraPosition: {
                x: psychJson.camera_position[0],
                y: psychJson.camera_position[1]
            },
            textures: [for (image in psychJson.image.split(',')) image.trim()],
            flipX: psychJson.flip_x,
            antialiasing: !psychJson.no_antialiasing,
            barColor: StringTools.hex(CoolUtil.colorFromArray(psychJson.healthbar_colors)),
            death: psychJson.deadVariant ?? 'bf-dead',
            sustainAnimation: true,
            danceModulo: char.contains('gf') ? 1 : 2,
            format: CHARACTER_FORMAT
        };

        for (anim in psychJson.animations)
            result.animations.push({
                prefix: anim.name,
                animation: anim.anim,
                framerate: anim.fps,
                loop: anim.loop,
                indices: anim.indices,
                offset: {
                    x: anim.offsets[0],
                    y: anim.offsets[1]
                }
            });

        return result;
    }

    public static function getStrumLine(strl:String):ALEStrumLine
    {
        return cast Paths.json('strumLines/' + strl);
    }
}