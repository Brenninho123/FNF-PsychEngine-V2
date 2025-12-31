package psychlua;

import flixel.FlxBasic;
import objects.Character;
import psychlua.LuaUtils;
import psychlua.CustomSubstate;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import tea.SScript;

class HScript extends SScript
{
	public var modFolder:String;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;

	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent, code, varsToBring);
		}
		else
		{
			hs.doString(code);
			@:privateAccess
			if(hs.parsingException != null)
			{
				PlayState.instance.addTextToDebug(
					'ERROR ON LOADING (${hs.origin}): ${hs.parsingException.message}',
					FlxColor.RED
				);
			}
		}
	}
	#end

	public var origin:String;
	var varsToBring:Any = null;

	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null)
	{
		if (file == null) file = '';

		this.varsToBring = varsToBring;
		super(file, false, false);

		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null)
		{
			origin = parent.scriptName;
			modFolder = parent.modFolder;
		}
		#end

		if (scriptFile != null && scriptFile.length > 0)
		{
			origin = scriptFile;
			#if MODS_ALLOWED
			var myFolder:Array<String> = scriptFile.split('/');
			if(myFolder[0] + '/' == Paths.mods()
				&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
				modFolder = myFolder[1];
			#end
		}

		preset();
		execute();
	}

	override function preset()
	{
		super.preset();

		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', CustomFlxColor);
		set('Countdown', backend.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('StorageUtil', StorageUtil);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('CustomSubstate', CustomSubstate);

		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);

		set('setVar', function(name:String, value:Dynamic) {
			PlayState.instance.variables.set(name, value);
			return value;
		});
		set('getVar', function(name:String) {
			return PlayState.instance.variables.get(name);
		});
		set('removeVar', function(name:String) {
			return PlayState.instance.variables.remove(name);
		});

		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		set('getFPS', () -> Std.int(FlxG.drawFramerate));
		set('getUpdateFPS', () -> Std.int(FlxG.updateFramerate));

		set('getSongTime', () -> Conductor.songPosition);
		set('getSongTimeSeconds', () -> Conductor.songPosition / 1000);
		set('getBeat', () -> Std.int(Conductor.curBeat));
		set('getStep', () -> Std.int(Conductor.curStep));

		set('cameraShake', function(cam:String, intensity:Float, duration:Float) {
			var c = (cam == 'hud') ? FlxG.cameras.list[1] : FlxG.camera;
			if(c != null) c.shake(intensity, duration);
		});
		set('cameraFlash', function(cam:String, color:Int, duration:Float) {
			var c = (cam == 'hud') ? FlxG.cameras.list[1] : FlxG.camera;
			if(c != null) c.flash(color, duration);
		});
		set('cameraFade', function(cam:String, color:Int, duration:Float, ?fadeIn:Bool = false) {
			var c = (cam == 'hud') ? FlxG.cameras.list[1] : FlxG.camera;
			if(c != null) c.fade(color, duration, fadeIn);
		});

		set('tweenX', (obj, v, t) -> FlxTween.tween(obj, {x: v}, t));
		set('tweenY', (obj, v, t) -> FlxTween.tween(obj, {y: v}, t));
		set('tweenAlpha', (obj, v, t) -> FlxTween.tween(obj, {alpha: v}, t));
		set('tweenAngle', (obj, v, t) -> FlxTween.tween(obj, {angle: v}, t));

		set('randomInt', (a, b) -> FlxG.random.int(a, b));
		set('randomFloat', (a, b) -> FlxG.random.float(a, b));

		set('isPaused', () -> PlayState.instance.paused);
		set('pauseGame', () -> PlayState.instance.openPauseMenu());
		set('resumeGame', () -> PlayState.instance.closeSubState());

		set('isMobile', () -> #if mobile true #else false #end);
		set('isDesktop', () -> #if desktop true #else false #end);

		#if mobile
		set('vibrate', (ms:Int = 100) -> lime.ui.Haptic.vibrate(0, ms));
		#end

		set('this', this);
		set('game', FlxG.state);

		if(varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
				set(k, Reflect.field(varsToBring, k));
			varsToBring = null;
		}
	}

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end
		super.destroy();
	}
}

class CustomFlxColor
{
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var RED(default, null):Int = FlxColor.RED;

	public static function fromRGB(r:Int,g:Int,b:Int,a:Int=255):Int
		return cast FlxColor.fromRGB(r,g,b,a);
}
#end