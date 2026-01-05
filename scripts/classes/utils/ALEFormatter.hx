package utils;

//import core.structures.ALESongStrumLine;

class ALEFormatter
{
    public static function getCharacter(char:String):ALECharacter
    {
        return Paths.json('characters/' + char);
    }

    public static function getStrumLine(strl:String):ALESongStrumLine
    {
        return cast Paths.json('strumLines/' + strl);
    }
}