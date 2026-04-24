package;

import utils.Formatter;

final CHART:ALESong;

function new(?chart:ALESong)
{
    CHART = chart ?? Formatter.getSong('bopeebo', 'hard');
}

var grids:FlxTypedGroup<ChartGrid>;

function onCreate()
{
    Conductor.bpm = CHART.sections[0] != null && CHART.sections[0].bpm && CHART.sections[0].changeBPM ? CHART.sections[0].bpm : CHART.bpm;

    Conductor.beatsPerSection = CHART.beatsPerSection;
    Conductor.stepsPerBeat = CHART.stepsPerBeat;

    grids = new FlxTypedGroup<ChartGrid>();
    add(grids);

    for (strl in CHART.strumLines)
    {
        grids.add(new ChartGrid(strl));
    }
}