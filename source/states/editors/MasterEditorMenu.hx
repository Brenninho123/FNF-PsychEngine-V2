package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

import objects.Alphabet;
import objects.Character;

import backend.MusicBeatState; 

import states.MainMenuState;
import states.FreeplayState;

import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import states.editors.WeekEditorState;
import states.editors.MenuCharacterEditorState;
import states.editors.DialogueEditorState;
import states.editors.DialogueCharacterEditorState;
import states.editors.NoteSplashDebugState;

class MasterEditorMenu extends MusicGameState
{
    var options:Array<String> = [
        'Chart Editor',
        'Character Editor',
        'Week Editor',
        'Menu Character Editor',
        'Dialogue Editor',
        'Dialogue Portrait Editor',
        'Note Splash Debug'
    ];

    private var grpTexts:FlxGroup;
    private var curSelected:Int = 0;

    override function create()
    {
        FlxG.camera.bgColor = FlxColor.BLACK;

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set();
        bg.color = 0xFF353535;
        add(bg);

        grpTexts = new FlxGroup();
        add(grpTexts);

        for (i in 0...options.length)
        {
            var leText:Alphabet = new Alphabet(FlxG.width * 0.1, 200 + i * 50, options[i], true);
            leText.isMenuItem = true;
            grpTexts.add(leText);
            leText.snapToPosition();
        }

        changeSelection();
        FlxG.mouse.visible = false;

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (controls.UI_UP_P)
            changeSelection(-1);
        if (controls.UI_DOWN_P)
            changeSelection(1);

        if (controls.BACK)
            MusicGameState.switchState(new MainMenuState());

        if (controls.ACCEPT)
        {
            switch(options[curSelected])
            {
                case 'Chart Editor':
                    LoadingState.loadAndSwitchState(new ChartingState(), false);
                case 'Character Editor':
                    LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
                case 'Week Editor':
                    MusicGameState.switchState(new WeekEditorState());
                case 'Menu Character Editor':
                    MusicGameState.switchState(new MenuCharacterEditorState());
                case 'Dialogue Editor':
                    LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
                case 'Dialogue Portrait Editor':
                    LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
                case 'Note Splash Debug':
                    MusicGameState.switchState(new NoteSplashDebugState());
            }

            FlxG.sound.music.volume = 0;
            FreeplayState.destroyFreeplayVocals();
        }

        // Cast necessário para acessar targetY e alpha
        for (i in 0...grpTexts.members.length)
        {
            var item:Alphabet = cast grpTexts.members[i];
            item.targetY = i - curSelected;
            item.alpha = if(item.targetY == 0) 1 else 0.6;
        }

        super.update(elapsed);
    }

    function changeSelection(change:Int = 0)
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        curSelected += change;

        if (curSelected < 0)
            curSelected = options.length - 1;
        if (curSelected >= options.length)
            curSelected = 0;
    }
}