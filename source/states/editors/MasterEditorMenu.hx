package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxTypedGroup;
import flixel.ui.FlxButton;

import backend.WeekData;
import objects.Alphabet;
import states.MainMenuState;
import states.FreeplayState;

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
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];
	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		// Background
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		// Adiciona opções
		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320 + i * 40, options[i], true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}

		#if MODS_ALLOWED
		// Barra de diretório
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(0, textBG.y + 4, FlxG.width, '', 24);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, "center");
		directoryTxt.scrollFactor.set();
		add(directoryTxt);

		for (folder in Mods.getModDirectories())
			directories.push(folder);

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end

		changeSelection();
		FlxG.mouse.visible = false;

		#if mobile
		#if MODS_ALLOWED
		addTouchPad("LEFT_FULL", "A_B");
		#else
		addTouchPad("UP_DOWN", "A_B");
		#end
		#end

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		#if MODS_ALLOWED
		if (controls.UI_LEFT_P) changeDirectory(-1);
		if (controls.UI_RIGHT_P) changeDirectory(1);
		#end

		if (controls.BACK)
			MusicBeatState.switchState(new MainMenuState());

		if (controls.ACCEPT)
			activateOption();

		// Atualiza posição e alpha do texto
		var index:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = index - curSelected;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
			index++;
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected += change;
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;
		if (curDirectory < 0) curDirectory = directories.length - 1;
		if (curDirectory >= directories.length) curDirectory = 0;

		WeekData.setDirectoryFromWeek();

		if (directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< NO MOD DIRECTORY LOADED >';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< LOADED MOD DIRECTORY: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end

	function activateOption()
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
}