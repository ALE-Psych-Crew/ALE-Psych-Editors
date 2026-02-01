using StringTools;

// ------- ADRIANA SALTE ------- //

function onHotReloadingConfig()
{
    for (pack in ['utils', 'funkin.visuals.game', 'funkin.visuals.objects', 'funkin.visuals'])
        for (file in Paths.readDirectory('scripts/classes/' + pack.replace('.', '/')))
            addHotReloadingFile('scripts/classes/' + pack.replace('.', '/') + '/' + file);
}

if (true)
{
    final window:Window = lime.app.Application.current.window;

    final screenSize:FlxPoint = flixel.math.FlxPoint.get(1920, 1080);

    window.width = screenSize.x / 2 * 0.9;
    window.height = screenSize.y / 2 * 0.9;
    window.x = screenSize.x / 4 - window.width / 2;
    window.y = screenSize.y / 4 - window.height / 2 + 40;
}

// ------- ADRIANA SALTE ------- //

