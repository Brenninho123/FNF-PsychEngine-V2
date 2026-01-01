package states;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	#if mobile
	var warnTextMobile:FlxText;
	#else
	var warnText:FlxText;
	#end

	var bg:FlxSprite;

	override function create()
	{
		super.create();

		// Background preto
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		// Mensagem de aviso
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

		controls.isInSubstate = false;

		// Adiciona efeito pulsante no fundo
		FlxTween.tween(bg, {alpha:0.5}, 0.8, {ease: FlxEase.sineInOut})
			.loop()
			.yoyo();

		// Adiciona efeito de flicker no texto
		#if mobile
		FlxFlicker.flicker(warnTextMobile, 0.5, 0.2, true, true);
		#else
		FlxFlicker.flicker(warnText, 0.5, 0.2, true, true);
		#end

		#if mobile
		addTouchPad("NONE", "A_B");
		#end
	}

	override function update(elapsed:Float)
	{
		if(!leftState)
		{
			var back:Bool = controls.BACK;

			if (controls.ACCEPT || back)
			{
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				if(!back)
				{
					ClientPrefs.data.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));

					#if mobile
					FlxTween.tween(warnTextMobile, {alpha:0}, 0.5, {
						ease: FlxEase.sineInOut,
						onComplete: function(_) { MusicBeatState.switchState(new TitleState()); }
					});
					#else
					FlxTween.tween(warnText, {alpha:0}, 0.5, {
						ease: FlxEase.sineInOut,
						onComplete: function(_) { MusicBeatState.switchState(new TitleState()); }
					});
					#end
				}
				else
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));

					#if mobile
					FlxTween.tween(warnTextMobile, {alpha:0}, 0.5, {
						ease: FlxEase.sineInOut,
						onComplete: function(_) { MusicBeatState.switchState(new TitleState()); }
					});
					#else
					FlxTween.tween(warnText, {alpha:0}, 0.5, {
						ease: FlxEase.sineInOut,
						onComplete: function(_) { MusicBeatState.switchState(new TitleState()); }
					});
					#end
				}
			}
		}
		super.update(elapsed);
	}
}