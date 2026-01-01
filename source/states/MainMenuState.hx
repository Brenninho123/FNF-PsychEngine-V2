package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;
import options.OptionsState;
import states.editors.MasterEditorMenu;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = "0.7.7"; // For Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxGroup;
	var optionShit:Array<String> = [
		"story_mode",
		"freeplay",

		#if MODS_ALLOWED
		"mods",
		#end

		"options"
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var selectedSomethin:Bool = false;

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
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image("menuBG"));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image("menuDesat"));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxGroup();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas("mainmenu/menu_" + optionShit[i]);
			menuItem.animation.addByPrefix("idle", optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix("selected", optionShit[i] + " white", 24);
			menuItem.animation.play("idle");
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
		}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);

		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v" + Application.current.meta.get("version"), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock("friday_night_play");

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if mobile
		addTouchPad("UP_DOWN", "A_B_E");
		#end

		super.create();
		FlxG.camera.follow(camFollow, null, 9);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);
			if (controls.UI_DOWN_P)
				changeItem(1);
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound("cancelMenu"));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				handleSelection();
			}
			else if (controls.justPressed("debug_1"))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function handleSelection()
	{
		FlxG.sound.play(Paths.sound("confirmMenu"));
		if (optionShit[curSelected] == "donate")
		{
			CoolUtil.browserLoad("https://ninja-muffin24.itch.io/funkin");
		}
		else
		{
			selectedSomethin = true;

			if (ClientPrefs.data.flashing)
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

			var current:FlxSprite = cast(menuItems.members[curSelected], FlxSprite);
			FlxFlicker.flicker(current, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				switch(optionShit[curSelected])
				{
					case "story_mode": MusicBeatState.switchState(new StoryMenuState());
					case "freeplay": MusicBeatState.switchState(new FreeplayState());
					#if MODS_ALLOWED
					case "mods": MusicBeatState.switchState(new ModsMenuState());
					#end
					case "options":
						MusicBeatState.switchState(new OptionsState());
						OptionsState.onPlayState = false;
						if (PlayState.SONG != null)
						{
							PlayState.SONG.arrowSkin = null;
							PlayState.SONG.splashSkin = null;
							PlayState.stageUI = "normal";
						}
				}
			});

			for (i in 0...menuItems.members.length)
			{
				if (i == curSelected) continue;
				var item:FlxSprite = cast(menuItems.members[i], FlxSprite);
				FlxTween.tween(item, {alpha:0}, 0.4, {ease: null, onComplete: function(twn:FlxTween) item.kill()});
			}
		}
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound("scrollMenu"));

		var prev:FlxSprite = cast(menuItems.members[curSelected], FlxSprite);
		prev.animation.play("idle");
		prev.updateHitbox();
		prev.screenCenter(X);

		curSelected += huh;
		if (curSelected >= menuItems.members.length) curSelected = 0;
		if (curSelected < 0) curSelected = menuItems.members.length - 1;

		var current:FlxSprite = cast(menuItems.members[curSelected], FlxSprite);
		current.animation.play("selected");
		current.centerOffsets();
		current.screenCenter(X);

		camFollow.setPosition(
			current.getGraphicMidpoint().x,
			current.getGraphicMidpoint().y - (menuItems.members.length > 4 ? menuItems.members.length * 8 : 0)
		);
	}
}