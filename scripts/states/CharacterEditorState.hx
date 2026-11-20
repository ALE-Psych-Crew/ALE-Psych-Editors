import ale.ui.objects.*;
import ale.ui.Config;

import UIUtil;

function postCreate()
{
    camGame.bgColor = FlxColor.GRAY;

    initSettingsTab();

    initCharacterTab();
}

final tabGS:MultiTab;

final tabGSSetReload:Button;
final tabGSSetPlayable:CheckBox;
final tabGSSetDropDown:DropDownMenu;

final tabGSGhoMake:Button;
final tabGSGhoOpacity:Slider;

function initSettingsTab()
{
    final list = UIUtil.jsonsList('characters');

    tabGS = new MultiTab(1, 1, ['Ghost', 'Settings'], 'Ghost', 12, 5);
    add(tabGS);
    tabGS.place(1, 1, true);

    tabGSSetReload = new Button(7, 1, 'Reload', null, 4, 1, {color: FlxColor.GRAY});
    tabGS.addObj('Settings', tabGSSetReload);

    tabGSSetPlayable = new CheckBox(1, 3, 'Playable');
    tabGS.addObj('Settings', tabGSSetPlayable);

    tabGSSetDropDown = new DropDownMenu(1, 1, list, list[0], 'Character...', 4);
    tabGS.addObj('Settings', tabGSSetDropDown);

    tabGSGhoMake = new Button(1, 1, 'Make Ghost', null, 10);
    tabGS.addObj('Ghost', tabGSGhoMake);

    tabGSGhoOpacity = new Slider(1, 3, 0, 1, 1, true, 10);
    tabGS.addObj('Ghost', tabGSGhoOpacity);

    tabGS.camera = camHUD;
}

final tabAC:MultiTab;

final tabACAniDropDown:DropDownMenu;
final tabACAniName:InputText;
final tabACAniPrefix:InputText;
final tabACAniIndices:InputText;
final tabACAniLoop:CheckBox;
final tabACAniFramerate:NumericStepper;

function initCharacterTab()
{
    tabAC = new MultiTab(1, 1, ['Animations', 'Character'], 'Animations', 15, 15);
    add(tabAC);
    tabAC.place(1, 8, true);

    tabACAniDropDown = new DropDownMenu(1, 1, ['oso'], 'oso', 'Animation...', 5);
    tabAC.addObj('Animations', tabACAniDropDown);

    tabACAniName = new InputText(8, 1, 'Name...', '', null, 6);
    tabAC.addObj('Animations', tabACAniName);

    tabACAniPrefix = new InputText(1, 3, 'Prefix...', '', null, 6);
    tabAC.addObj('Animations', tabACAniPrefix);

    tabACAniIndices = new InputText(8, 3, 'Indices...', '', null, 6);
    tabAC.addObj('Animations', tabACAniIndices);

    tabACAniLoop = new CheckBox(1, 5, 'Looped');
    tabAC.addObj('Animations', tabACAniLoop);

    tabACAniFramerate = new NumericStepper(8, 5, 0, 100, 24);
    tabAC.addObj('Animations', tabACAniFramerate);

    tabAC.camera = camHUD;
}