package utils;

//import core.structures.ALESongStrumLine;

class ALEFormatter
{
    public static function getStrumLine(strl:String):ALESongStrumLine
    {
        return cast Paths.json('strumLines/' + strl);
    }
}