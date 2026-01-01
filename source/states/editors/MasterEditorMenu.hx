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

class MasterEditorMenu extends MusicBeatState
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
            var leText:Alphabet = new Alphabet(FlxG.width / 2 - 150, 200 + i * 50, options[i], true);
            leText.isMenuItem = true;
            grpTexts.add(leText);
            leText.snapToPosition();
        }

        changeSelection();
        FlxG.mouse.visible = false;

        #if mobile
        addTouchPad("UP_DOWN", "A_B");
        #end

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (controls.UI_UP_P)
            changeSelection(-1);
        if (controls.UI_DOWN_P)
            changeSelection(1);

        if (controls.BACK)
            MusicBeatState.switchState(new MainMenuState());

        if (controls.ACCEPT)
        {
            switch(options[curSelected])
            {
                case 'Chart Editor':
                    LoadingState.loadAndSwitchState(new ChartingState(), false);
                case 'Character Editor':
                    LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
                case 'Week Editor':
                    MusicBeatState.switchState(new WeekEditorState());
                case 'Menu Character Editor':
                    MusicBeatState.switchState(new MenuCharacterEditorState());
                case 'Dialogue Editor':
                    LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
                case 'Dialogue Portrait Editor':
                    LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
                case 'Note Splash Debug':
                    MusicBeatState.switchState(new NoteSplashDebugState());
            }

            FlxG.sound.music.volume = 0;
            FreeplayState.destroyFreeplayVocals();
        }

        // Atualiza alfa e pulsar do item selecionado
        for (i in 0...grpTexts.members.length)
        {
            var item:Alphabet = cast grpTexts.members[i];
            item.targetY = i - curSelected;
            item.alpha = if(item.targetY == 0) 1 else 0.6;

            if(item.targetY == 0)
                item.scale.set(1.1, 1.1);
            else
                item.scale.set(1, 1);
        }

        super.update(elapsed);
    }

    function changeSelection(change:Int = 0)
    {
        if (change == 0) return;
        curSelected += change;
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        if (curSelected < 0)
            curSelected = options.length - 1;
        if (curSelected >= options.length)
            curSelected = 0;
    }
}