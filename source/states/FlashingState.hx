package states;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	#if mobile
	var warnTextMobile:FlxText;
	#else
	var warnText:FlxText;
	#end

	var bg:FlxSprite;
	var countdown:Float = 10; // segundos antes de ignorar automaticamente
	var countdownText:FlxText;

	override function create()
	{
		super.create();

		// fundo preto
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		// texto de aviso
		#if mobile
		var guhMobile:String = "Hey, watch out!\nThis Mod contains some flashing lights!\nPress A to disable them now or go to Options Menu.\nPress B to ignore this message.\nYou've been warned!";
		warnTextMobile = new FlxText(0, 0, FlxG.width, guhMobile, 32);
		warnTextMobile.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnTextMobile.screenCenter(Y);
		add(warnTextMobile);
		#else
		var guh:String = "Hey, watch out!\nThis Mod contains some flashing lights!\nPress ENTER to disable them now or go to Options Menu.\nPress ESCAPE to ignore this message.\nYou've been warned!";
		warnText = new FlxText(0, 0, FlxG.width, guh, 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
		#end

		// contador visual
		countdownText = new FlxText(0, FlxG.height - 80, FlxG.width, "Auto-ignore in: " + countdown + "s", 24);
		countdownText.setFormat("VCR OSD Mono", 24, FlxColor.RED, CENTER);
		add(countdownText);

		#if mobile
		addTouchPad("NONE", "A_B");
		#end

		// efeito de pulsação no fundo
		FlxTween.tween(bg, {alpha:0.5}, 0.8, {ease:FlxTween.SINE_INOUT, loop:true, yoyo:true});
		
		// efeito de piscar no texto
		#if mobile
		FlxFlicker.flicker(warnTextMobile, 999, 0.7, true);
		#else
		FlxFlicker.flicker(warnText, 999, 0.7, true);
		#end
	}

	override function update(elapsed:Float)
	{
		// decrementa contagem
		countdown -= elapsed;
		countdownText.text = "Auto-ignore in: " + Math.ceil(countdown) + "s";

		if (countdown <= 0 && !leftState) {
			leftState = true;
			autoIgnore();
		}

		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				if(!back) disableFlashing();
				else ignoreFlashing();
			}
		}

		super.update(elapsed);
	}

	// desliga efeitos e retorna ao título
	function disableFlashing()
	{
		ClientPrefs.data.flashing = false;
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		#if mobile
		FlxFlicker.flicker(warnTextMobile, 1, 0.1, false, true, function(flk:FlxFlicker) {
			new FlxTimer().start(0.5, function (tmr:FlxTimer) {
				MusicBeatState.switchState(new TitleState());
			});
		});
		#else
		FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
			new FlxTimer().start(0.5, function (tmr:FlxTimer) {
				MusicBeatState.switchState(new TitleState());
			});
		});
		#end
	}

	function ignoreFlashing()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		#if mobile
		FlxTween.tween(warnTextMobile, {alpha: 0}, 1, {
			onComplete: function (twn:FlxTween) {
				MusicBeatState.switchState(new TitleState());
			}
		});
		#else
		FlxTween.tween(warnText, {alpha: 0}, 1, {
			onComplete: function (twn:FlxTween) {
				MusicBeatState.switchState(new TitleState());
			}
		});
		#end
	}

	function autoIgnore()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		#if mobile
		FlxTween.tween(warnTextMobile, {alpha: 0}, 0.5, {onComplete:function(twn) MusicBeatState.switchState(new TitleState())});
		#else
		FlxTween.tween(warnText, {alpha: 0}, 0.5, {onComplete:function(twn) MusicBeatState.switchState(new TitleState())});
		#end
	}
}