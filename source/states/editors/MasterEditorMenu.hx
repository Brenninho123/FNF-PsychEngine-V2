package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

import objects.Alphabet;
import objects.Character;

import states.EditorState;
import states.MainMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import states.editors.WeekEditorState;
import states.editors.MenuCharacterEditorState;
import states.editors.DialogueEditorState;
import states.editors.DialogueCharacterEditorState;
import states.editors.NoteSplashDebugState;
import openfl.Assets;

class MasterEditorMenu extends EditorState
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

        // Background
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set();
        bg.color = 0xFF353535;
        add(bg);

        // Menu Texts
        grpTexts = new FlxGroup();
        add(grpTexts);

        for (i in 0...options.length)
        {
            var leText:Alphabet = new Alphabet(FlxG.width * 0.1, 200 + i * 50, options[i], true);
            leText.isMenuItem = true;
            leText.targetY = i;
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
            EditorState.switchState(new MainMenuState());

        if (controls.ACCEPT)
        {
            switch(options[curSelected])
            {
                case 'Chart Editor':
                    LoadingState.loadAndSwitchState(new ChartingState(), false);
                case 'Character Editor':
                    LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
                case 'Week Editor':
                    EditorState.switchState(new WeekEditorState());
                case 'Menu Character Editor':
                    EditorState.switchState(new MenuCharacterEditorState());
                case 'Dialogue Editor':
                    LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
                case 'Dialogue Portrait Editor':
                    LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
                case 'Note Splash Debug':
                    EditorState.switchState(new NoteSplashDebugState());
            }

            FlxG.sound.music.volume = 0;
            FreeplayState.destroyFreeplayVocals();
        }

        var index:Int = 0;
        for (item in grpTexts.members)
        {
            item.targetY = index - curSelected;
            item.alpha = if(item.targetY == 0) 1 else 0.6;
            index++;
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