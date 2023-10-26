package backend;

import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import openfl.filters.ShaderFilter;
import shaders.Shaders.BloomHandler;
import shaders.Shaders.BrightHandler;
import shaders.Shaders.ChromaHandler;
import substates.DiamondTransSubState;
#if mobileC
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
#end
import flixel.addons.plugin.screengrab.FlxScreenGrab;

class MusicBeatState extends FlxUIState
{
	public static var instance:MusicBeatState;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public var controls(get, never):Controls;

	private function get_controls()
	{
		return Controls.instance;
	}

	#if mobileC
	public var virtualPad:FlxVirtualPad;
	public var mobileControls:MobileControls;
	public var camControls:FlxCamera;
	public var vpadCam:FlxCamera;

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		virtualPad = new FlxVirtualPad(DPad, Action);
		virtualPad.alpha = ClientPrefs.data.controlsAlpha;
		add(virtualPad);
	}

	public function removeVirtualPad()
	{
		if (virtualPad != null)
			remove(virtualPad);
	}

	public function addMobileControls(DefaultDrawTarget:Bool = true):Void
	{
		mobileControls = new MobileControls();

		camControls = new FlxCamera();
		camControls.bgColor.alpha = 0;
		FlxG.cameras.add(camControls, DefaultDrawTarget);

		mobileControls.cameras = [camControls];
		mobileControls.visible = false;
		mobileControls.alpha = ClientPrefs.data.controlsAlpha;
		add(mobileControls);
		// configure the current mobile control binds, without this there gonna be conflict and input issues.
		switch (MobileControls.getMode())
		{
			case 0 | 1 | 2: // RIGHT_FULL, LEFT_FULL and CUSTOM
				ClientPrefs.mobileBinds = controls.mobileBinds = [
					'note_up' => [UP],
					'note_left' => [LEFT],
					'note_down' => [DOWN],
					'note_right' => [RIGHT],

					'ui_up' => [UP], // idk if i remove these the controls in menus gonna get fucked
					'ui_left' => [LEFT],
					'ui_down' => [DOWN],
					'ui_right' => [RIGHT],

					'accept' => [A],
					'back' => [B],
					'pause' => [NONE],
					'reset' => [NONE],

					'attack'			=> [attack],
					'dodge'			=> [dodge]
				];
			case 3: // BOTH
				ClientPrefs.mobileBinds = controls.mobileBinds = [
					'note_up' => [UP, UP2],
					'note_left' => [LEFT, LEFT2],
					'note_down' => [DOWN, DOWN2],
					'note_right' => [RIGHT, RIGHT2],

					'ui_up' => [UP],
					'ui_left' => [LEFT],
					'ui_down' => [DOWN],
					'ui_right' => [RIGHT],

					'accept' => [A],
					'back' => [B],
					'pause' => [NONE],
					'reset' => [NONE],

					'attack'			=> [attack],
					'dodge'			=> [dodge]
				];
			case 4: // HITBOX
				ClientPrefs.mobileBinds = controls.mobileBinds = [
					'note_up' => [hitboxUP],
					'note_left' => [hitboxLEFT],
					'note_down' => [hitboxDOWN],
					'note_right' => [hitboxRIGHT],

					'ui_up' => [UP],
					'ui_left' => [LEFT],
					'ui_down' => [DOWN],
					'ui_right' => [RIGHT],

					'accept' => [A],
					'back' => [B],
					'pause' => [NONE],
					'reset' => [NONE],

					'attack'			=> [attack],
					'dodge'			=> [dodge]
				];
			case 5: // KEYBOARD
				// sex, idk maybe nothin'?
		}
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
			remove(mobileControls);
	}

	public function addPadCamera(DefaultDrawTarget:Bool = true):Void
	{
		if (virtualPad != null)
		{
			vpadCam = new FlxCamera();
			vpadCam.bgColor.alpha = 0;
			FlxG.cameras.add(vpadCam, DefaultDrawTarget);
			virtualPad.cameras = [vpadCam];
		}
	}
	#end

	override function destroy()
	{
		// Paths.clearStoredMemory();
		// Paths.clearUnusedMemory();
		FlxG.game.setFilters(null);
		FlxG.game.filtersEnabled = false;
		super.destroy();

		#if mobileC
		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (mobileControls != null)
		{
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			mobileControls = null;
		}
		#end
	}

	public static var camBeat:FlxCamera;

	override function create()
	{
		// Paths.clearStoredMemory();
		// Paths.clearUnusedMemory();
		instance = this;
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		super.create();

		if (!skip)
		{
			FlxG.state.openSubState(new DiamondTransSubState(0.5, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public static var timePassedOnState:Float = 0;

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		if(FlxG.keys.justPressed.F11)
			FlxG.fullscreen = !FlxG.fullscreen;

		if(FlxG.keys.justPressed.F5)
			FlxScreenGrab.grab(FlxScreenGrab.region, true, false);

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null)
	{
		// Custom made Trans in
		if (!FlxTransitionableState.skipNextTransIn)
		{
			FlxG.state.openSubState(new DiamondTransSubState(0.5, false));
			if (nextState == FlxG.state)
			{
				DiamondTransSubState.finishCallback = function()
				{
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				DiamondTransSubState.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	// BRIGHT SHADER
	public var brightShader(get, never):ShaderFilter;

	inline function get_brightShader():ShaderFilter
		return BrightHandler.brightShader;

	public function setBrightness(brightness:Float):Void
		BrightHandler.setBrightness(brightness);

	public function setContrast(contrast:Float):Void
		BrightHandler.setContrast(contrast);

	// CHROMATIC SHADER
	public var chromaticAberration(get, never):ShaderFilter;

	inline function get_chromaticAberration():ShaderFilter
		return ChromaHandler.chromaticAberration;

	public function setChrome(daChrome:Float):Void
		ChromaHandler.setChrome(daChrome);

	// BLOOM SHADER
	public var bloomShader(get, never):ShaderFilter;

	inline function get_bloomShader():ShaderFilter
		return BloomHandler.bloomShader;

	public function setThreshold(value:Float)
		BloomHandler.setThreshold(value);

	public function setIntensity(value:Float)
		BloomHandler.setIntensity(value);

	public function setBlurSize(value:Float)
		BloomHandler.setBlurSize(value);
}
