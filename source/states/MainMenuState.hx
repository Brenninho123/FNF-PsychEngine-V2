package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
    public static var psychEngineVersion:String = '0.7.7';
    public static var curSelected:Int = 0;

    var menuItems:FlxTypedGroup<FlxSprite>;
    var optionShit:Array<String> = [
        'story_mode',
        'freeplay',
        #if MODS_ALLOWED
        'mods',
        #end
        'options'
    ];

    var magenta:FlxSprite;
    var camFollow:FlxObject;

    // Novas variáveis
    var pulseTimer:Float = 0;
    var prevSelected:Int = -1;

    // Cores do fundo para cada item
    var bgColors:Array<Int> = [0xFF353535, 0xFF3a3a3a, 0xFF444444, 0xFF505050];
    var targetColor:Int;

    override function create()
    {
        #if MODS_ALLOWED
        Mods.pushGlobalMods();
        #end
        Mods.loadTopMod();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("In the Menus", null);
        #end

        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;

        persistentUpdate = persistentDraw = true;

        var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, yScroll);
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);

        magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
        magenta.antialiasing = ClientPrefs.data.antialiasing;
        magenta.scrollFactor.set(0, yScroll);
        magenta.setGraphicSize(Std.int(magenta.width * 1.175));
        magenta.updateHitbox();
        magenta.screenCenter();
        magenta.visible = true; // Ativo para ver o efeito
        magenta.color = bgColors[0]; // Começa com a primeira cor
        add(magenta);
        targetColor = bgColors[0];

        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);

        for (i in 0...optionShit.length)
        {
            var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
            var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
            menuItem.antialiasing = ClientPrefs.data.antialiasing;
            menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
            menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
            menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
            menuItem.animation.play('idle');
            menuItem.scale.set(1, 1);
            menuItems.add(menuItem);
            var scr:Float = (optionShit.length - 4) * 0.135;
            if (optionShit.length < 6)
                scr = 0;
            menuItem.scrollFactor.set(0, scr);
            menuItem.updateHitbox();
            menuItem.screenCenter(X);
        }

        changeItem();

        #if mobile
        addTouchPad("UP_DOWN", "A_B_E");
        #end

        super.create();
        FlxG.camera.follow(camFollow, null, 9);
    }

    var selectedSomethin:Bool = false;

    override function update(elapsed:Float)
    {
        pulseSelectedItem(elapsed);
        updateBackgroundColor(elapsed);
        updateVolume(elapsed);

        if (!selectedSomethin)
        {
            #if mobile
            handleMobileSelection();
            #else
            handleDesktopSelection();
            #end
        }

        super.update(elapsed);
    }

    function updateVolume(elapsed:Float)
    {
        if (FlxG.sound.music.volume < 0.8)
        {
            FlxG.sound.music.volume += 0.5 * elapsed;
            if (FreeplayState.vocals != null)
                FreeplayState.vocals.volume += 0.5 * elapsed;
        }
    }

    function handleMobileSelection()
    {
        if (controls.UI_UP_P) changeItem(-1);
        if (controls.UI_DOWN_P) changeItem(1);
        if (controls.BACK)
        {
            selectedSomethin = true;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new TitleState());
        }
        if (controls.ACCEPT) confirmSelection();
        else if (controls.justPressed('debug_1') || touchPad.buttonE.justPressed) openEditorShortcut();
    }

    function handleDesktopSelection()
    {
        if (controls.UI_UP_P) changeItem(-1);
        if (controls.UI_DOWN_P) changeItem(1);
        if (controls.BACK)
        {
            selectedSomethin = true;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new TitleState());
        }
        if (controls.ACCEPT) confirmSelection();
        else if (controls.justPressed('debug_1')) openEditorShortcut();
    }

    function confirmSelection()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        if (optionShit[curSelected] == 'donate')
        {
            CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
            return;
        }

        selectedSomethin = true;
        if (ClientPrefs.data.flashing)
            FlxFlicker.flicker(magenta, 1.1, 0.15, false);

        FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
        {
            switch (optionShit[curSelected])
            {
                case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
                case 'freeplay': MusicBeatState.switchState(new FreeplayState());
                #if MODS_ALLOWED
                case 'mods': MusicBeatState.switchState(new ModsMenuState());
                #end
                case 'options':
                    MusicBeatState.switchState(new OptionsState());
                    OptionsState.onPlayState = false;
                    if (PlayState.SONG != null)
                    {
                        PlayState.SONG.arrowSkin = null;
                        PlayState.SONG.splashSkin = null;
                        PlayState.stageUI = 'normal';
                    }
            }
        });

        for (i in 0...menuItems.members.length)
        {
            if (i == curSelected) continue;
            FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
                ease: FlxEase.quadOut,
                onComplete: function(twn:FlxTween) { menuItems.members[i].kill(); }
            });
        }
    }

    function changeItem(huh:Int = 0)
    {
        prevSelected = curSelected;
        curSelected += huh;
        if (curSelected >= menuItems.length) curSelected = 0;
        if (curSelected < 0) curSelected = menuItems.length - 1;

        targetColor = bgColors[curSelected % bgColors.length];

        if (prevSelected != -1 && prevSelected != curSelected)
        {
            FlxTween.tween(menuItems.members[prevSelected], {scaleX:1, scaleY:1}, 0.2, {ease:FlxEase.quadOut});
            FlxTween.tween(menuItems.members[curSelected], {scaleX:1.2, scaleY:1.2}, 0.2, {ease:FlxEase.quadOut});
        }
        else menuItems.members[curSelected].scale.set(1.2,1.2);

        for (i in 0...menuItems.members.length)
        {
            if (i != curSelected)
                menuItems.members[i].animation.play('idle');
        }

        menuItems.members[curSelected].animation.play('selected');
        menuItems.members[curSelected].centerOffsets();
        menuItems.members[curSelected].screenCenter(X);

        camFollow.setPosition(
            menuItems.members[curSelected].getGraphicMidpoint().x,
            menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0)
        );
    }

    function pulseSelectedItem(elapsed:Float)
    {
        if (menuItems.members.length <= 0) return;
        pulseTimer += elapsed;
        var scaleAmount = 1.2 + Math.sin(pulseTimer * 3) * 0.03;
        menuItems.members[curSelected].scale.set(scaleAmount, scaleAmount);
    }

    function updateBackgroundColor(elapsed:Float)
    {
        if (magenta == null) return;
        var currentColor:Int = magenta.color;
        // Suaviza a transição da cor do fundo
        magenta.color = Std.int(currentColor + (targetColor - currentColor) * elapsed * 4);
    }

    function resetMenu()
    {
        curSelected = 0;
        prevSelected = -1;
        for (i in 0...menuItems.members.length)
        {
            menuItems.members[i].alpha = 1;
            menuItems.members[i].scale.set(1,1);
            menuItems.members[i].animation.play('idle');
        }
        changeItem(0);
    }

    function openEditorShortcut()
    {
        selectedSomethin = true;
        MusicBeatState.switchState(new MasterEditorMenu());
    }
}