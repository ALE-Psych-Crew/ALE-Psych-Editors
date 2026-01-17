import ale.ui.ALEUIUtils;

import core.config.DiscordRPC;

function onCreate()
{
    DiscordRPC.changePresence('In the Menus: ' + game.scriptName, null);
}

function onUpdate(elapsed:Float)
{
    if (FlxG.keys.justPressed.R && CoolVars.data.developerMode && !ALEUIUtils.usingInputs)
        resetCustomState();
}