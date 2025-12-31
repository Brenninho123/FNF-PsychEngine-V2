package psychlua;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

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
	public var origin:String;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	#end

	public static function initHaxeModule(parent:FunkinLua)
	{
		if (parent.hscript == null)
			parent.hscript = new HScript(parent);
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		if (parent.hscript == null)
			parent.hscript = new HScript(parent, code, varsToBring);
		else
			parent.hscript.doString(code);
	}

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

		preset();
		execute();
	}

	override function preset()
	{
		super.preset();

		// ===============================
		// CORE
		// ===============================
		set('FlxG', FlxG);
		set('FlxMath', FlxMath);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('FlxTimer', FlxTimer);
		set('FlxColor', CustomFlxColor);

		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);

		set('Character', Character);
		set('Note', objects.Note);
		set('CustomSubstate', CustomSubstate);

		// ===============================
		// VARIABLES
		// ===============================
		set('setVar', (name:String, value:Dynamic) ->
		{
			PlayState.instance.variables.set(name, value);
			return value;
		});

		set('getVar', (name:String) ->
		{
			return PlayState.instance.variables.exists(name)
				? PlayState.instance.variables.get(name)
				: null;
		});

		set('removeVar', (name:String) ->
		{
			return PlayState.instance.variables.remove(name);
		});

		// ===============================
		// DEBUG
		// ===============================
		set('debugPrint', (text:String, ?color:Int = null) ->
		{
			if (color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		// ===============================
		// SONG / TIMING (SAFE)
		// ===============================
		set('getSongTime', () -> Conductor.songPosition);
		set('getSongTimeSeconds', () -> Conductor.songPosition / 1000);

		set('getBeat', () ->
		{
			return Math.floor(Conductor.songPosition / Conductor.crochet);
		});

		set('getStep', () ->
		{
			return Math.floor(Conductor.songPosition / Conductor.stepCrochet);
		});

		// ===============================
		// PAUSE (SAFE)
		// ===============================
		set('isPaused', () ->
		{
			return PlayState.instance != null && PlayState.instance.paused;
		});

		set('pauseGame', () ->
		{
			if (!PlayState.instance.paused)
			{
				PlayState.instance.paused = true;
				FlxG.sound.music.pause();
			}
		});

		set('resumeGame', () ->
		{
			if (PlayState.instance.paused)
			{
				PlayState.instance.paused = false;
				FlxG.sound.music.resume();
			}
		});

		// ===============================
		// CAMERA
		// ===============================
		set('cameraShake', (intensity:Float, duration:Float) ->
		{
			FlxG.camera.shake(intensity, duration);
		});

		set('cameraFlash', (color:Int, duration:Float) ->
		{
			FlxG.camera.flash(color, duration);
		});

		set('cameraFade', (color:Int, duration:Float, ?fadeIn:Bool = false) ->
		{
			FlxG.camera.fade(color, duration, fadeIn);
		});

		// ===============================
		// RANDOM / MATH
		// ===============================
		set('randomInt', (min:Int, max:Int) -> FlxG.random.int(min, max));
		set('randomFloat', (min:Float, max:Float) -> FlxG.random.float(min, max));
		set('lerp', (a:Float, b:Float, t:Float) -> FlxMath.lerp(a, b, t));

		// ===============================
		// PLATFORM
		// ===============================
		set('isMobile', () ->
		{
			#if mobile
			return true;
			#else
			return false;
			#end
		});

		#if LUA_ALLOWED
		set('parentLua', parentLua);
		#else
		set('parentLua', null);
		#end

		set('this', this);
		set('game', FlxG.state);

		if (varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
				set(k, Reflect.field(varsToBring, k));
			varsToBring = null;
		}
	}

	public function executeCode(?func:String, ?args:Array<Dynamic>):TeaCall
	{
		if (func == null || !exists(func)) return null;
		return call(func, args);
	}

	public function executeFunction(func:String, args:Array<Dynamic>):TeaCall
	{
		return call(func, args);
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		funk.addLocalCallback("runHaxeCode", function(code:String, ?vars:Any = null, ?func:String = null, ?args:Array<Dynamic> = null)
		{
			#if SScript
			initHaxeModuleCode(funk, code, vars);
			if (func != null)
			{
				var ret = funk.hscript.executeCode(func, args);
				return ret != null ? ret.returnValue : null;
			}
			#end
			return null;
		});

		funk.addLocalCallback("runHaxeFunction", function(func:String, ?args:Array<Dynamic> = null)
		{
			#if SScript
			var ret = funk.hscript.executeFunction(func, args);
			return ret != null ? ret.returnValue : null;
			#else
			return null;
			#end
		});
	}
	#end

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end
		super.destroy();
	}
}

class CustomFlxColor
{
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var BLUE(default, null):Int = FlxColor.BLUE;

	public static function fromRGB(r:Int, g:Int, b:Int, a:Int = 255):Int
	{
		return cast FlxColor.fromRGB(r, g, b, a);
	}
}
#end