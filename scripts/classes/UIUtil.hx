package;

import core.enums.ReadDirectoryType;
import core.enums.FileType;

using StringTools;

class UIUtil
{
    static var jsonExt(get, never):String;
    static function get_jsonExt():String
        return Paths?.config[FileType.JSON]?.postfix ?? '.json';

    public static function jsonsList(folder:String):Array<String>
        return Paths.readDirectory('data/' + folder, FileType.MULTIPLE).filter(f -> f.endsWith(jsonExt)).map(f -> f.substr(0, f.length - jsonExt.length));
}