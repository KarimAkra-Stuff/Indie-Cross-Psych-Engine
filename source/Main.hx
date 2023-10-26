package;

import flixel.addons.plugin.screengrab.FlxScreenGrab;
import states.FreeplayState;
import backend.SUtil;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.system.System;
import states.TitleState;
#if linux
import lime.graphics.Image;
#end

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		#if desktop
		framerate: 120, // default framerate
		#else
		framerate: 60, // default framerate
		#end
		skipSplash: false, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;

	public static var allowedToClear:Bool = true; // this is used for proper memory cleaning and preventing your game from loading everything over and over for no reason

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end
	}

	public function new()
	{
		super();

		SUtil.uncaughtErrorHandler();

		/*#if cpp
			untyped __global__.__hxcpp_set_critical_error_handler(SUtil.onCriticalError);
			#elseif hl
			Api.setErrorHandler(SUtil.onCriticalError);
			#end */

		// https://github.com/MAJigsaw77/UTF/blob/main/source/Main.hx
		FlxG.signals.preStateCreate.add(function(state:FlxState)
		{
			// Clear the loaded graphics if they are no longer in flixel cache...
			for (key in Assets.cache.getBitmapKeys())
				if (!FlxG.bitmap.checkCache(key))
					Assets.cache.removeBitmapData(key);

			// Clear all the loaded sounds from the cache...
			for (key in Assets.cache.getSoundKeys())
				Assets.cache.removeSound(key);

			// Run the garbage colector...
			System.gc();
		});
		FlxG.signals.postStateSwitch.add(System.gc);

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if MODS_ALLOWED
		SUtil.checkFiles();
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate,
			game.skipSplash, game.startFullscreen));
		FlxG.save.bind('indie-cross-psych', CoolUtil.getSavePath());
		ClientPrefs.saveSettings();
		ClientPrefs.loadPrefs();
		Achievements.load();

		#if debug
		FlxG.console.registerClass(PlayState);
		FlxG.console.registerClass(FreeplayState);
		FlxG.console.registerClass(TitleState);
		FlxG.console.registerClass(CoolUtil);
		FlxG.console.registerClass(MusicBeatState);
		FlxG.console.registerClass(MusicBeatSubstate);
		#end



		fpsVar = new FPS(10, 5, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = ClientPrefs.data.showFPS;
		}

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if (desktop && !hl)
		DiscordClient.start();
		#end

		// screenshot?
		FlxScreenGrab.defineCaptureRegion(0, 0, FlxG.width, FlxG.height);

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					@:privateAccess
					if (cam != null && cam._filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
			// fixes image width and height on resize
			FlxScreenGrab.clearCaptureRegion();
			FlxScreenGrab.defineCaptureRegion(0, 0, w, h);

		});
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
