function onHotReloadingConfig()
{
    for (folder in ['scripts/classes'])
        for (file in Paths.readDirectory(folder))
            addHotReloadingFile(folder + '/' + file);
}

if (true)
{
    final oldFullScreen:Bool = FlxG.fullscreen;

    FlxG.fullscreen = false;

    final window:Window = lime.app.Application.current.window;

    final screenSize:FlxPoint = flixel.math.FlxPoint.get(1920, 1080);

    window.width = screenSize.x / 2 * 0.9;
    window.height = screenSize.y / 2 * 0.9;
    window.x = screenSize.x / 4 - window.width / 2;
    window.y = screenSize.y / 4 - window.height / 2 + 40;

    FlxG.fullscreen = oldFullScreen;
}