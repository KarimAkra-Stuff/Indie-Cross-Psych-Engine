package states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.
// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
import backend.Highscore;
import backend.Rating;
import backend.Section;
import backend.Song;
import backend.StageData;
import backend.WeekData;
import cutscenes.CutsceneHandler;
import cutscenes.DialogueBoxPsych;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.ui.FlxBar;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import lime.utils.Assets;
import objects.*;
import objects.Note.EventNote;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;
import shaders.BlendModeEffect;
import states.FreeplayState;
import states.StoryMenuState;
import states.editors.CharacterEditorState;
import states.editors.ChartingState;
import states.stages.objects.*;
import states.stages.*;
import substates.GameOverSubstate;
import substates.PauseSubState;
// import tjson.TJSON as Json;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.display.Shader;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import shaders.CustomShaders;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1")
import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0")
import VideoHandler;
#else
import vlc.MP4Handler as VideoHandler;
#end
import backend.VideoSpriteManager;
import backend.VideoManager;
#end
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.FunkinLua;
import psychlua.HScript;
import psychlua.LuaUtils;
#end
#if (SScript >= "3.0.0")
import tea.SScript;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#end

	#if !flash
	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var shaderUpdates:Array<Float->Void> = [];
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	#end
	public var filters:Array<BitmapFilter> = [];

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel";

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var mechsDifficulty:Int = 1;
	public static var scoreMuti:Float = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;

	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var fullComboFunction:Void->Void = null;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var cupheadGameOver:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camDialogue:FlxCamera;
	public var camVideo:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if (desktop && !hl)
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];

	#if LUA_ALLOWED
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end

	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;

	public var precacheList:Map<String, String> = new Map<String, String>();
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	public var songEndCallback:Void->Void = function() {};
	public var videoEndCallback:Void->Void = function() {};

	// smooth healthbar
	var healthTweenObj:FlxTween;

	// karma healthbar for sans
	public var krTweenObj:FlxTween;
	public  var krBar:FlxBar;
	public var kr:Float = 0.0;
	public var hpTxt:FlxSprite;
	var sansColors:Bool = false;

	public var dialoguePaused:Bool = false;

	#if VIDEOS_ALLOWED
	public var finishedVideo:Bool = false;
	public var video:VideoHandler;
	public var videoSprites:Array<VideoSpriteManager>;
	#end

	public var brightFyreVal:Float = 0;
	public var brightMagnitude:Float = 0;
	public var brightSpeed:Float = 0;
	public var defaultBrightVal:Float = 0;

	public var chromVal:Float;

	public var alarm:FlxSprite;
	public var bfDodge:FlxSprite;
	public var alarmbone:FlxSprite;

	public var canPressSpace:Bool = false;
	public var pressedSpace:Bool = false;
	public var attackCooldown:Float = 0;

	public var attackHud:HudIcon;
	public var dodgeHud:HudIcon;

	var lastUpdatedPos:Float = 0;

	public var attacked:Bool = false;

	public var bumpRate:Float = 4;
	public var utMode:Bool = false;

	public var soul:Soul;
	public var blaster:FlxTypedGroup<FlxSprite>;

	public var utmode:Bool = false;
	public var cangethurt:Bool = true;

	// cuphead bullets
	public var cupheadPewMode:Bool = false;
	public var cupheadChaserMode:Bool = false;

	var cupheadPewFX:CupBullet;

	public var cupBullets:Array<CupBullet> = [];

	var cupheadPew:CupBullet;
	var canCupheadShoot:Bool = true;
	var pewdmg:Float = 0;
	var pewdmgScale:Float = 1.0;
	var pewhits:Int = 0;
	var cardbary = 0.0;
	var cardtween:FlxTween;
	var cardanims:FlxSprite;
	var cardbar:FlxBar;
	var cardfloat:Float = 0;
	var didntdoanimyet:Bool = true;
	var poped:Bool = true;

	override public function create()
	{
		#if debug
		//chartingMode = true;
		#end
		// trace('Playback Rate: ' + playbackRate);
		trace(mechsDifficulty);
		Paths.clearStoredMemory();

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; // Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		fullComboFunction = fullComboUpdate;

		keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');

		healthTweenObj = FlxTween.tween(this, {}, 0);
		krTweenObj = FlxTween.tween(this, {}, 0);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camDialogue = new FlxCamera();
		camDialogue.bgColor = 0;
		camVideo = new FlxCamera();
		camVideo.bgColor = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camDialogue, false);
		FlxG.cameras.add(camVideo, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		DiamondTransSubState.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if (desktop && !hl)
		storyDifficultyText = Difficulty.getString();

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		var fuckingWeekString:String = 'your mom';
		if (StoryMenuState.curWeek == 0)
			fuckingWeekString = 'Cuphead';
		else if (StoryMenuState.curWeek == 1)
			fuckingWeekString = 'Sans';
		else if (StoryMenuState.curWeek == 2)
			fuckingWeekString = 'Bendy';
		else
			fuckingWeekString = 'tf is he playing?';
		if (isStoryMode)
			detailsText = "Story Mode: " + fuckingWeekString;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else
		{
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage':
				new StageWeek1(); // Week 1
			case 'hall':
				new Hall(); // sans
			case 'nightmare-hall':
				new Hall(); // sans
			case 'field':
				new Field(); // cuphead
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'scripts/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (SONG.gfVersion == null || SONG.gfVersion.length < 1)
			SONG.gfVersion = 'gf'; // Fix for the Chart Editor
		gf = new Character(0, 0, SONG.gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterScripts(gf.curCharacter);
		gf.alpha = 0;

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}
		if(SONG.song.toLowerCase() == 'burning-in-hell')
		{
			blaster = new FlxTypedGroup<FlxSprite>();
			add(blaster);
			var b:FlxSprite;
			b = new FlxSprite().loadGraphic(Paths.image('Gaster_blasterss', 'sans'));
			b.alpha = 0.0001;
			add(b);	
			soul = new Soul(Hall.battleBG.x + 940, Hall.battleBG.y + 1560);
			soul.alpha = 0.0001;
			add(soul);
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());

		// INITIALIZE UI GROUPS
		uiGroup = new FlxSpriteGroup();
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		comboGroup = new FlxSpriteGroup();

		Conductor.songPosition = -5000 / Conductor.songPosition;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(CoolUtil.returnHudFont(timeTxt), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if (ClientPrefs.data.downScroll)
			timeTxt.y = FlxG.height - 44;
		if (ClientPrefs.data.timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), '', 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		timeBar.overlay.visible = false;
		timeBar.leftBar.color = CoolUtil.colorFromString(stageData.timeBarColor);
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		add(comboGroup);
		add(strumLineNotes);
		add(grpNoteSplashes);
		add(uiGroup);

		if (ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100);
		splash.setupNoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		if (!utmode)
			moveCameraSection();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), stageData.healthBarOverlay, stageData.healthBarBg,
			function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		healthBar.leftToRight = false;
		healthBar.bg.x += stageData.healthBarBgX;
		healthBar.bg.y += stageData.healthBarBgY;
		healthBar.overlay.x += stageData.healthBarOverlayX;
		healthBar.overlay.y += stageData.healthBarOverlayY;
		if (stageData.healthBarOverlay == "" || stageData.healthBarOverlay == null || stageData.healthBarOverlay == 'sans')
			healthBar.overlay.visible = false;
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true, boyfriend.animatedHealthIcon);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false, dad.animatedHealthIcon);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);
		iconP2.playNormalAnim(true);

		attackHud = new HudIcon(6, 235, 'attack');
		dodgeHud = new HudIcon(6, 145 + attackHud.height, 'dodge');
		if (SONG.song.toLowerCase() == 'technicolor-tussle'
			|| SONG.song.toLowerCase() == 'knockout'
			|| SONG.song.toLowerCase() == 'devils-gambit')
		{
			cardbar = new FlxBar(0, 0, TOP_TO_BOTTOM, 97, 144, this, 'cardfloat', 0, 200);
			cardbar.scrollFactor.set(0, 0);
			cardbar.x = healthBar.x + 670;
			cardbar.y = healthBar.y + 15;
			cardbar.createImageEmptyBar(Paths.image('cardempty', 'cup'), FlxColor.WHITE);
			cardbar.createImageFilledBar(Paths.image('cardfull', 'cup'), FlxColor.WHITE);
			uiGroup.add(cardbar);

			cardanims = new FlxSprite();
			cardanims.frames = Paths.getSparrowAtlas('Cardcrap', 'cup');
			cardanims.x = healthBar.x + 665;
			cardanims.y = healthBar.y - 67 - (100 / 1.5) + 5;
			cardanims.animation.addByPrefix('parry', 'PARRY Card Pop out  instance 1', 24, false);
			cardanims.animation.addByPrefix('pop', "Card Normal Pop out instance 1", 24, false);
			cardanims.animation.addByPrefix('use', "Card Used instance 1", 24, false);
			cardanims.animation.play('pop', true);
			cardanims.alpha = 0.0001;
			cardanims.antialiasing = true;
			cardanims.scrollFactor.set(0, 0);
			uiGroup.add(cardanims);

			if (ClientPrefs.data.downScroll)
			{
				cardbary += 65;
				cardanims.y += 65;
			}
		}
		switch (SONG.song.toLowerCase())
		{
			case 'last-reel':
				uiGroup.add(attackHud);
				uiGroup.add(dodgeHud);
			case 'despair':
				uiGroup.add(attackHud);
				uiGroup.add(dodgeHud);
				attackHud.alpha = 0.0001;
				dodgeHud.alpha = 0.0001;
			case 'sansational' | 'burning-in-hell':
				uiGroup.add(attackHud);
				if(mechsDifficulty != 0)
				uiGroup.add(dodgeHud);
			case 'whoopee':
				if(mechsDifficulty != 0)
					uiGroup.add(dodgeHud);
			case 'technicolor-tussle':
				uiGroup.add(attackHud);
			case 'knockout' | 'devils-gambit':
				if(mechsDifficulty != 0){
					uiGroup.add(attackHud);
					uiGroup.add(dodgeHud);
				}
			case 'satanic-funkin':
				if(mechsDifficulty != 0)
					uiGroup.add(dodgeHud);
			case 'ritual':
				if(mechsDifficulty != 0){
					uiGroup.add(dodgeHud);
					dodgeHud.alpha = 0.0001;
				}
			case 'bad-time':
				if(mechsDifficulty != 0)
					uiGroup.add(dodgeHud);
		}


		if (curStage.endsWith("hall"))
			addSansBar();
		else if (curStage == 'field')
			chromVal = 0.002;
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(CoolUtil.returnHudFont(scoreTxt), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		updateScore(false);
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(CoolUtil.returnHudFont(botplayTxt), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if (ClientPrefs.data.downScroll)
			botplayTxt.y = timeBar.y - 78;

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		uiGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];
		#if mobileC
		var buttonLeftColor:Array<FlxColor>;
		var buttonDownColor:Array<FlxColor>;
		var buttonUpColor:Array<FlxColor>;
		var buttonRightColor:Array<FlxColor>;
		if (ClientPrefs.data.dynamicColors)
		{
			buttonLeftColor = ClientPrefs.data.arrowRGB[0];
			buttonDownColor = ClientPrefs.data.arrowRGB[1];
			buttonUpColor = ClientPrefs.data.arrowRGB[2];
			buttonRightColor = ClientPrefs.data.arrowRGB[3];
		}
		else
		{
			buttonLeftColor = ClientPrefs.defaultData.arrowRGB[0];
			buttonDownColor = ClientPrefs.defaultData.arrowRGB[1];
			buttonUpColor = ClientPrefs.defaultData.arrowRGB[2];
			buttonRightColor = ClientPrefs.defaultData.arrowRGB[3];
		}
		addMobileControls(false);
		mobileControls.visible = true;
		if (ClientPrefs.data.dynamicColors)
		{
			switch (mobile.MobileControls.getMode())
			{
				case 0 | 1 | 2:
					mobileControls.virtualPad.buttonLeft.color = buttonLeftColor[0];
					mobileControls.virtualPad.buttonDown.color = buttonDownColor[0];
					mobileControls.virtualPad.buttonUp.color = buttonUpColor[0];
					mobileControls.virtualPad.buttonRight.color = buttonRightColor[0];
				case 3:
					mobileControls.virtualPad.buttonLeft.color = buttonLeftColor[0];
					mobileControls.virtualPad.buttonDown.color = buttonDownColor[0];
					mobileControls.virtualPad.buttonUp.color = buttonUpColor[0];
					mobileControls.virtualPad.buttonRight.color = buttonRightColor[0];
					mobileControls.virtualPad.buttonLeft2.color = buttonLeftColor[0];
					mobileControls.virtualPad.buttonDown2.color = buttonDownColor[0];
					mobileControls.virtualPad.buttonUp2.color = buttonUpColor[0];
					mobileControls.virtualPad.buttonRight2.color = buttonRightColor[0];
			}
		}
		#end

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		if (eventNotes.length > 1)
		{
			for (event in eventNotes)
				event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/' + songName + '/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

		startCallback();
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.data.hitsoundVolume > 0)
			precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null)
		{
			precacheList.set(PauseSubState.songName, 'music');
		}
		else if (ClientPrefs.data.pauseMusic != 'None')
		{
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');
		resetRPC();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnScripts('onCreatePost');

		cacheCountdown();
		cachePopUpScore();

		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		#if (mobileC && !android)
		addVirtualPad(NONE, P);
		addPadCamera(false);
		#end

		super.create();
		Paths.clearUnusedMemory();

		DiamondTransSubState.nextCamera = camOther;
		if (eventNotes.length < 1)
			checkEventNote();

		// camHUD.setFilters(filters);
		// camGame.setFilters(filters);
		// camOther.setFilters(filters);
		addChromaticAbberation();
		FlxG.game.setFilters(filters);
		FlxG.game.filtersEnabled = ClientPrefs.data.shaders;

	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if (generatedMusic)
		{
			if (vocals != null)
				vocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor)
	{
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#end
	}

	public function reloadHealthBarColors()
	{
		if (sansColors)
		{
			healthBar.setColors(FlxColor.YELLOW, FlxColor.RED);
		}
		else
		{
			healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
				FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if (FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = SUtil.getPath() + Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if (Assets.exists(luaFile))
			doPush = true;
		#end

		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if (doPush)
				new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		var replacePath:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		{
			scriptFile = Paths.getPreloadPath(scriptFile);
			if (FileSystem.exists(scriptFile))
				doPush = true;
		}

		if (doPush)
		{
			if (SScript.global.exists(scriptFile))
				doPush = false;

			if (doPush)
				initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
		{
			#if VIDEOS_ALLOWED
			inCutscene = true;
	
			var filepath:String = Paths.video(name);
			#if sys
			if (!FileSystem.exists(filepath))
			#else
			if (!OpenFlAssets.exists(filepath))
			#end
			{
				FlxG.log.warn('Couldnt find video file: ' + name);
				startAndEnd();
				return;
			}
	
			video = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				videoEndCallback();
				startAndEnd();
				return;
				finishedVideo = true;
			}, true);
			#else
			// Older versions
			video.canSkip = true;
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				return FunkinLua.Function_Continue;
				trace('video ended plz start countdown or go back to menu');
				videoEndCallback();
				startAndEnd();
				return;
				finishedVideo = true;
			}
			#end
			#else
			FlxG.log.warn('Platform not supported!');
			startAndEnd();
			return;
			#end
		}
	
		public function noCountdownVideo(name:String)
		{
			#if VIDEOS_ALLOWED
			inCutscene = true;
	
			var filepath:String = Paths.video(name);
			#if sys
			if (!FileSystem.exists(filepath))
			#else
			if (!OpenFlAssets.exists(filepath))
			#end
			{
				FlxG.log.warn('Couldnt find video file: ' + name);
			}
	
			video = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				finishedVideo = true;
			}, true);
			#else
			// Older versions
			video.canSkip = true;
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				finishedVideo = true;
			}
			#end
			#else
			FlxG.log.warn('Platform not supported!');
			return;
			#end
		}
	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	public function sanesIntroShit()
	{
		var theDialogue:Array<String> = [];
		inCutscene = true;
		#if VIDEOS_ALLOWED
		finishedVideo = true;
		#end

		switch (SONG.song.toLowerCase())
		{
			case 'whoopee':
				theDialogue = [
					'welcome to the underground:normal:none:',
					'how was your fall?:funne:none:',
					'...:gay:none:',
					'you know, i was hired to tear you to shreds:eyesclosed:none:',
					'and spread those pieces across 6 different suns.:noeyes:none:',
					'...:eyesclosed:none:',
					'after a few rounds of rap battling...:wink:none:',
					'for some reason...:funne:none:',
					'Ready yourself Human.:noeyes:none:'
				];
			case 'sansational':
				theDialogue = [
					'you see, i cant judge the book by its cover but...:normal:none:',
					'i know what happened with you and that cup guy.:gay:none:',
					"i'd say if you try to do the same with me...:eyesclosed:none:",
					'things wont turn out so well.:funne:none:',
					'up to you kid....:normal:none:',
					'No Pressure.:noeyes:none:'
				];
			case 'burning-in-hell':
				theDialogue = ['Bring It.:noeyes:eye--0.6:'];
			case 'final-stretch':
				theDialogue = [
					'im surprised you didnt try anything.:normal:none:',
					'i guess you learned something from last time...:wink:none:',
					'Lets finish this.:noeyes:none:'
				];
			default:
				return;
		}
		var dialogue = new cutscenes.SansDialogueBox(theDialogue);
		dialogue.cameras = [camDialogue];
		add(dialogue);
		dialogue.finishThing = function()
		{
			if (SONG.song.toLowerCase() == 'burning-in-hell')
			{
				boyfriend.playAnim('attack', true, false, 0);

				FlxG.sound.play(Paths.sound('Throw' + FlxG.random.int(1, 3), 'sans'));
				new FlxTimer().start(0.375, function(tmr:FlxTimer)
				{
					dad.playAnim('miss', true, false, 0);
					FlxG.sound.play(Paths.sound('dodge', 'sans'), 0.6);
					startCountdown();
					FlxG.camera.shake(0.005);
				});
			}
			else
			{
				seenCutscene = true;
				startCountdown();
			}
		};
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch (stageUI)
		{
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set", "go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
		{
			#if mobileC mobileControls.visible = true; #end
			if (startedCountdown)
			{
				callOnScripts('onStartCountdown');
				return false;
			}
	
			seenCutscene = true;
			inCutscene = false;
			var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
			if (ret != FunkinLua.Function_Stop)
			{
				if (skipCountdown || startOnTime > 0)
					skipArrowStartTween = true;
				if (!curStage.endsWith("hall"))
				{
					skipArrowStartTween = true;
					for (i in 0...4)
					{
						generateStaticArrows(0, i, true);
						generateStaticArrows(1, i, true);
					}
				}
				Conductor.songPosition = -Conductor.crochet * 5;
				setOnScripts('startedCountdown', true);
				callOnScripts('onCountdownStarted', null);
				var swagCounter:Int = 0;
				if (startOnTime > 0)
				{
					clearNotesBefore(startOnTime);
					setSongTime(startOnTime - 350);
					return true;
				}
				else if (skipCountdown)
				{
					startedCountdown = true;
					setSongTime(0);
					return true;
				}
				if (!utmode)
					moveCameraSection();
				
				if (curStage == 'field'){
					startedCountdown = true;
					startSong();
					setSongTime(0);
					Field.cupIntro();
					return true;
				}
				else
					{
					startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
					{
						if (gf != null
							&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
							&& gf.animation.curAnim != null
							&& !gf.animation.curAnim.name.startsWith("sing")
							&& !gf.stunned)
							gf.dance();
							if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
							&& boyfriend.animation.curAnim != null
							&& !boyfriend.animation.curAnim.name.startsWith('sing')
							&& !boyfriend.stunned)
							boyfriend.dance();
							if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
							&& dad.animation.curAnim != null
							&& !dad.animation.curAnim.name.startsWith('sing')
							&& !dad.stunned)
							dad.dance();
							
							var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
							var introImagesArray:Array<String> = switch (stageUI)
							{
								case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
								case "normal": ["ready", "set", "go"];
								default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
							}
							introAssets.set(stageUI, introImagesArray);
							
							var introAlts:Array<String> = introAssets.get(stageUI);
							var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
							var tick:Countdown = THREE;
						
						switch (swagCounter)
						{
							case 0:
								startedCountdown = true;
								if (curStage.endsWith("hall"))
									{
										generateStaticArrows(0, 0);
										generateStaticArrows(1, 0);
									}
									FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
									tick = THREE;
									case 1:
										if (curStage.endsWith("hall"))
											{
												generateStaticArrows(0, 1);
												generateStaticArrows(1, 1);
											}
											countdownReady = createCountdownSprite(introAlts[0], antialias);
											FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
								tick = TWO;
								case 2:
									if (curStage.endsWith("hall"))
										{
											generateStaticArrows(0, 2);
											generateStaticArrows(1, 2);
										}
										countdownSet = createCountdownSprite(introAlts[1], antialias);
										FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
										tick = ONE;
										case 3:
											if (curStage.endsWith("hall"))
												{
													generateStaticArrows(0, 3);
													generateStaticArrows(1, 3);
												}
												countdownGo = createCountdownSprite(introAlts[2], antialias);
												FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
												tick = GO;
												case 4:
									/*if (curStage.endsWith("hall"))
									{
										generateStaticArrows(0, 4);
										generateStaticArrows(1, 4);
									}*/
									tick = START;
									for (i in 0...playerStrums.length)
										{
											setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
											setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
										}
										for (i in 0...opponentStrums.length)
											{
									setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
									setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
									// if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
								}
						}
						
						notes.forEachAlive(function(note:Note)
							{
								if (ClientPrefs.data.opponentStrums || note.mustPress)
									{
										note.copyAlpha = false;
										note.alpha = note.multAlpha;
										if (ClientPrefs.data.middleScroll && !note.mustPress)
											note.alpha *= 0.35;
									}
								});
								
								stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
								callOnLuas('onCountdownTick', [swagCounter]);
						callOnHScript('onCountdownTick', [tick, swagCounter]);
	
						swagCounter += 1;
					}, 5);
				}
			}
			return true;
		}
	

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public var scoreSeparator:String = " | ";

	public function updateScore(miss:Bool = false)
	{
		var ret:Dynamic = callOnScripts('onUpdateScore', [miss]);
		if (ret == FunkinLua.Function_Stop)
			return;

		var str:String = ratingName;
		if (totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' ($percent%) - $ratingFC';
		}

		var scoreNew:String = 'Score: ' + Std.int(songScore * scoreMuti);
		if (!instakillOnMiss)
			scoreNew += scoreSeparator + 'Misses: ${songMisses}';
		scoreNew += scoreSeparator + 'Rating: ${str}';

		scoreTxt.text = scoreNew + "\n"; // "\n" here prevents the text being cut off by beat zooms depending on its size

		if (ClientPrefs.data.scoreZoom && !miss && !cpuControlled)
		{
			if (scoreTxtTween != null)
			{
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue()
	{
		++dialogueCount;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue()
	{
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;
		if (curStage != 'field')
		{
			@:privateAccess
			FlxG.sound.playMusic(inst._sound, 1, false);
		}
		else
		{
			@:privateAccess
			FlxG.sound.playMusic(inst._sound, 0.5, false);
			FlxG.sound.music.fadeIn(4.5, 0.5, 1);
		}
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if (startOnTime > 0)
			setSongTime(startOnTime - 500);
		startOnTime = 0;

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if (desktop && !hl)
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		if (songData.needsVoices)
			vocals.loadEmbedded(Paths.voices(songData.song));

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(SUtil.getPath() + file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);

				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						sustainNote.correctionOffset = swagNote.height / 2;
						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}
							if (ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}
						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if (ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if (!noteTypes.contains(swagNote.noteType))
				{
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) // Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);
		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote)
	{
		eventPushedUnique(event);
		if (eventsPushed.contains(event.event))
			{
				return;
			}
			
			stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
			eventsPushed.push(event.event);
		}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote)
	{
		switch (event.event)
		{

			case 'Sans Bones Attack':
				if(event.value1 != 'blue' && event.value1 != 'orange'){
				alarm = new FlxSprite();
					if (SONG.song.toLowerCase() == 'burning-in-hell')
						alarm.frames = Paths.getSparrowAtlas('Cardodge', 'sans');
					else
						alarm.frames = Paths.getSparrowAtlas('DodgeMechs', 'sans');
				alarm.animation.addByPrefix('play', 'Alarm instance', 24, false);
				alarm.animation.addByPrefix('DIE', 'Bones boi instance', 24, false);
				alarm.updateHitbox();
				alarm.antialiasing = true;
				alarm.alpha = 0.0001;
				alarm.x = boyfriend.x - 175;
				alarm.y = boyfriend.y - 100;
				add(alarm);
				trace('cached normal dodge shit');

				bfDodge = new FlxSprite();
				if (SONG.song.toLowerCase() == 'burning-in-hell')
				{
					bfDodge.frames = Paths.getSparrowAtlas('Cardodge', 'sans');
					bfDodge.x = boyfriend.x + 15;
					bfDodge.y = boyfriend.y + 25;
				}
				else
				{
					bfDodge.frames = Paths.getSparrowAtlas('DodgeMechs', 'sans');
					bfDodge.x = boyfriend.x + 25;
					bfDodge.y = boyfriend.y - 20;
				}
			
				bfDodge.animation.addByPrefix('Dodge', 'Dodge instance', 24, false);
				bfDodge.updateHitbox();
				bfDodge.antialiasing = true;
				bfDodge.alpha = 0.0001;
				add(bfDodge);
		} else {
				alarmbone = new FlxSprite();
				alarmbone.frames = Paths.getSparrowAtlas('Sans_Shit_NM', 'sans');
				alarmbone.animation.addByPrefix('playblue', 'AlarmBlue instance 1', 24, false);
				alarmbone.animation.addByPrefix('blue', 'Bones boi instance 1', 24, false);
				alarmbone.animation.addByPrefix('playorange', 'AlarmOrange instance 1', 24, false);
				alarmbone.animation.addByPrefix('orange', 'Bones Orange instance 1', 24, false);
				alarmbone.updateHitbox();
				alarmbone.antialiasing = true;
				alarmbone.alpha = 0.0001;
				alarmbone.x = boyfriend.x - 175;
				alarmbone.y = boyfriend.y - 100;
				alarmbone.blend = ADD;
				add(alarmbone);
				trace('cached blue and orange dodge shit');
				}
			case "Change Character":
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1))
							val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				precacheList.set(event.value1, 'sound');
				Paths.sound(event.value1);
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if (returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue)
		{
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [
			subEvent.event,
			subEvent.value1 != null ? subEvent.value1 : '',
			subEvent.value2 != null ? subEvent.value2 : '',
			subEvent.strumTime
		]);
	}

	#if (!flash && LUA_ALLOWED)
	public function addShaderToCamera(cam:String, effect:Dynamic)
	{ // STOLE FROM ANDROMEDA

		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for (i in camHUDShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for (i in camOtherShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for (i in camGameShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
			default:
				if (modchartSprites.exists(cam))
				{
					Reflect.setProperty(modchartSprites.get(cam), "shader", effect.shader);
				}
				else if (modchartTexts.exists(cam))
				{
					Reflect.setProperty(modchartTexts.get(cam), "shader", effect.shader);
				}
				else
				{
					var OBJ = Reflect.getProperty(PlayState.instance, cam);
					Reflect.setProperty(OBJ, "shader", effect.shader);
				}
		}
	}

	public function removeShaderFromCamera(cam:String, effect:ShaderEffect)
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camHUDShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camOtherShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.setFilters(newCamEffects);
			default:
				if (modchartSprites.exists(cam))
				{
					Reflect.setProperty(modchartSprites.get(cam), "shader", null);
				}
				else if (modchartTexts.exists(cam))
				{
					Reflect.setProperty(modchartTexts.get(cam), "shader", null);
				}
				else
				{
					var OBJ = Reflect.getProperty(PlayState.instance, cam);
					Reflect.setProperty(OBJ, "shader", null);
				}
		}
	}

	public function clearShaderFromCamera(cam:String)
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
			default:
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
		}
	}
	#end

	public var skipArrowStartTween:Bool = false; // for lua

	public function generateStaticArrows(player:Int, i:Int, ?delay:Bool = false):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		// FlxG.log.add(i);
		var targetAlpha:Float = 1;
		if (player < 1)
		{
			if (!ClientPrefs.data.opponentStrums)
				targetAlpha = 0;
			else if (ClientPrefs.data.middleScroll)
				targetAlpha = 0.35;
		}

		var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
		babyArrow.downScroll = ClientPrefs.data.downScroll;
		if (!isStoryMode && !skipArrowStartTween)
		{
			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			if (delay)
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			else
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut});
		}
		else
			babyArrow.alpha = targetAlpha;

		if (player == 1)
			playerStrums.add(babyArrow);
		else
		{
			if (ClientPrefs.data.middleScroll)
			{
				babyArrow.x += 310;
				if (i > 1)
				{ // Up and Right
					babyArrow.x += FlxG.width / 2 + 25;
				}
			}
			opponentStrums.add(babyArrow);
		}

		strumLineNotes.add(babyArrow);
		babyArrow.postAddedToGroup();
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if (char != null && char.colorTween != null)
					char.colorTween.active = false;

			#if LUA_ALLOWED
			for (tween in modchartTweens)
				tween.active = false;
			for (timer in modchartTimers)
				timer.active = false;
			#end
			if (cupBullets[0] != null)
			{
				cupBullets[0].cantmove = true;
				cupBullets[1].cantmove = true;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if (char != null && char.colorTween != null)
					char.colorTween.active = true;

			#if LUA_ALLOWED
			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;
			#end
			if (cupBullets[0] != null)
			{
				cupBullets[0].cantmove = false;
				cupBullets[1].cantmove = false;
			}

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		callOnScripts('onFocus');
		if (health > 0 && !paused)
			resetRPC(Conductor.songPosition > 0.0);

		super.onFocus();
		callOnScripts('onFocusPost');
	}

	override public function onFocusLost():Void
	{
		callOnScripts('onFocusLost');
		#if (desktop && !hl)
		if (health > 0 && !paused)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.onFocusLost();
		callOnScripts('onFocusLostPost');
	}

	// Updating Discord Rich Presence.
	function resetRPC(?cond:Bool = false)
	{
		#if (desktop && !hl)
		if (cond)
			DiscordClient.changePresence(detailsText, SONG.song
				+ " ("
				+ storyDifficultyText
				+ ")", iconP2.getCharacter(), true,
				songLength
				- Conductor.songPosition
				- ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	public var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		callOnScripts('onUpdate', [elapsed]);

		if (SONG.song.toLowerCase() == "burning-in-hell")
			checkBlasters(elapsed);
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
	}*/
		switch (SONG.song.toLowerCase())
		{
			case 'burning-in-hell' | 'sansational':
				attackCheck(SANS);
			case 'knockout' | 'technicolor-tussle':
				attackCheck(PEA);
		}
		setChrome(chromVal);
		if (canPressSpace && controls.justPressed('dodge'))
		{
			pressedSpace = true;
			dodgeHud.useHUD();
		}
		if (brightSpeed != 0)
		{
			brightFyreVal = defaultBrightVal + Math.sin((Conductor.songPosition / 1000) * (Conductor.bpm / 60) * brightSpeed) * brightMagnitude;
			setBrightness(brightFyreVal);
		}
		else
		{
			setBrightness(defaultBrightVal);
		}
		setContrast(1.0);
		if (cupheadPewMode && mechsDifficulty != 0)
		{
			if (canCupheadShoot && dad.animation.curAnim.name == 'attack')
			{
				if (dad.curCharacter == 'cupheadNightmare')
				{
					shootOnce(true);
				}
				else
				{
					shootOnce();
				}
				canCupheadShoot = false;
				new FlxTimer().start(0.15, function(tmr:FlxTimer)
				{
					canCupheadShoot = true;
				});
			}
		}
		else if (dad.animation.curAnim.name == 'shoot')
			dad.dance();
		if (cardbar != null && cardanims != null)
		{
			if (!poped || cardfloat == 200)
			{
				cardbar.alpha = 0.0001;
				cardanims.alpha = 1;
			}
			cardbar.y = cardbary + healthBar.y + 40 - (cardfloat / 1.5);
			if (cardanims.animation.curAnim.name == 'parry')
			{
				cardfloat = 200;
			}
		}
		if (cardfloat >= 200)
			cardfloat = 200;
		#if debug
		if (FlxG.keys.justPressed.FIVE && cardfloat < 200 && cardanims != null && curStage == 'field')
		{
			cardfloat = 200;
			cardanims.animation.play('pop', true);
		}
		#end

		FlxG.camera.followLerp = 0;
		if (!inCutscene && !paused)
		{
			FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * cameraSpeed * playbackRate / (FlxG.updateFramerate / 60), 0, 1);
			if (!startingSong
				&& !endingSong
				&& boyfriend.animation.curAnim != null
				&& boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if (botplayTxt != null && botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (#if !mobileC controls.PAUSE #elseif android FlxG.android.justReleased.BACK
			|| FlxG.keys.anyPressed(controls.keyboardBinds["pause"]) #elseif (mobileC && !android) virtualPad.buttonP.justPressed
			|| FlxG.keys.anyPressed(controls.keyboardBinds["pause"]) #end
			&& startedCountdown
			&& canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if (ret != FunkinLua.Function_Stop)
			{
				openPauseMenu();
			}
		}

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene)
			openChartEditor();

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;
		if (healthBar.bounds.max != null)
		{
			if (health > healthBar.bounds.max)
			{
				healthTweenObj.cancel();
				health = healthBar.bounds.max;
			}
		}
		else
		{
			// Old system for safety?? idk
			if (health > 2)
			{
				healthTweenObj.cancel();
				health = 2;
			}
		}
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		// iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0;
		// iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0;
		if(healthBar.percent > 20)
			iconP1.playNormalAnim();
		else if(healthBar.percent < 20)
			iconP1.playlossAnim();
		if(healthBar.percent < 80)
			iconP2.playNormalAnim();
		else if(healthBar.percent > 80)
			iconP2.playlossAnim();

		if (krBar !=null)
			{
				if (kr<health) {
					kr=health;
					krBar.alpha = 0;
				}
				if (kr>2)
					kr = 2;
				if (kr != health && kr > health) {
					krBar.alpha = healthBar.alpha;
					kr -= elapsed / 5.5;
				}
			}

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene)
			openCharacterEditor();

		if (startedCountdown && !paused)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0 && curStage != 'field')
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if (ClientPrefs.data.timeBarType == 'Time Elapsed')
				songCalc = curTime;

			var secondsTotal:Int = Math.floor((songCalc / playbackRate) / 1000);
			if (secondsTotal < 0)
				secondsTotal = 0;

			if (ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			healthTweenObj.cancel();
			health = 0;
			trace("RESET = True");
		}
		if (health <= 0 && !practiceMode)
			{
				if (!curStage.endsWith("hall"))
					doDeathCheck();
				else
					{
						if (kr <= 0)
							doDeathCheck();
						else
							kr += health;
						
					}
				health = 0;
				if (kr > 0)
					health = (2 / 99);
			}
	

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [
					notes.members.indexOf(dunceNote),
					dunceNote.noteData,
					dunceNote.noteType,
					dunceNote.isSustainNote,
					dunceNote.strumTime
				]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled)
				{
					keysCheck();
				}
				else if (boyfriend.animation.curAnim != null
					&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
						&& boyfriend.animation.curAnim.name.startsWith('sing')
						&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
					// boyfriend.animation.curAnim.finish();
				}

				if (notes.length > 0)
				{
					if (startedCountdown && playerStrums != null && opponentStrums != null)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if (!daNote.mustPress)
								strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							if(strum != null)
								daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if (daNote.mustPress)
							{
								if (cpuControlled
									&& !daNote.blockHit
									&& daNote.canBeHit
									&& (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition)
									&& (!boyfriend.stunned || !gf.stunned || !dad.stunned))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);
							if(daNote != null && strum != null)
							if (daNote.isSustainNote && strum.sustainReduce)
								daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = false;
								daNote.visible = false;

								notes.remove(daNote, true);
								daNote.destroy();
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (attackCooldown != 0)
			{
				if (attackCooldown != 0)
					attackHud.playAnim(Std.string(attackCooldown));
	
				if (Math.floor(FlxG.sound.music.time) > lastUpdatedPos + 1000)
				{
					lastUpdatedPos = Math.floor(FlxG.sound.music.time);
	
					attackCooldown--;
	
					if (attackCooldown == 0)
					{
						attackHud.useHUD();
					}
				}
			}

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
		#if !flash
		for (i in shaderUpdates)
		{
			i(elapsed);
		}
		#end
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			switchState(new GitarooPause());
		}
		else { */
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if (!cpuControlled)
		{
			for (note in playerStrums)
				if (note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		// }

		#if (desktop && !hl)
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		chartingMode = true;

		#if (desktop && !hl)
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		#if (desktop && !hl) DiscordClient.resetClientID(); #end
		switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if (ret != FunkinLua.Function_Stop)
			{
				boyfriend.stunned = true;
				++deathCounter;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				#if LUA_ALLOWED
				for (tween in modchartTweens)
				{
					tween.active = true;
				}
				for (timer in modchartTimers)
				{
					timer.active = true;
				}
				#end
				if (cupheadGameOver)
				{
					persistentDraw = true;

					if (Field.wallop != null)
					{
						Field.wallop.destroy();
						remove(Field.wallop);
					}

					FlxTween.tween(camHUD, {alpha: 0}, 1);
					FlxG.camera.shake(0.005);

					if (SONG.song.toLowerCase() == 'knockout')
					{
						FlxTween.tween(Field.fgRain, {alpha: 0}, 1);
						FlxTween.tween(Field.fgRain2, {alpha: 0}, 1);
					}

					FlxTween.tween(Field.fgStatic, {alpha: 0}, 1);
					FlxTween.tween(Field.fgGrain, {alpha: 0}, 1);

					openSubState(new substates.GameOverCuphead(Conductor.songPosition, FlxG.sound.music.length));
				}
				else
				{
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
						boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollow.x, camFollow.y));
				}

				// switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if (desktop && !hl)
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				return;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float)
	{
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if (Math.isNaN(flValue1))
			flValue1 = null;
		if (Math.isNaN(flValue2))
			flValue2 = null;

		switch (eventName)
		{
			case 'Sans Bones Attack':
				switch(value1.toLowerCase()){
					case 'blue':
						trace('blue bones');
						sansAttack(BLUE_BONES);
					case 'orange':
						trace('orange bones');
						sansAttack(ORANGE_BONES);
					default:
						trace('bones');
						sansAttack(BONES);
				}
			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if (flValue2 == null || flValue2 <= 0)
					flValue2 = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if (flValue1 == null || flValue1 < 1)
					flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
				{
					if (flValue1 == null)
						flValue1 = 0.015;
					if (flValue2 == null)
						flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if (flValue2 == null)
							flValue2 = 0;
						switch (Math.round(flValue2))
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if (camFollow != null)
				{
					isCameraOnForcedPos = false;
					if (flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if (flValue1 == null)
							flValue1 = 0;
						if (flValue2 == null)
							flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf')
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if (flValue1 == null)
						flValue1 = 1;
					if (flValue2 == null)
						flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if (flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if (split.length > 1)
					{
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], value2);
					}
					else
					{
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch (e:Dynamic)
				{
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
				}

			case 'Play Sound':
				if (flValue2 == null)
					flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	function moveCameraSection(?sec:Null<Int>):Void
	{
		if (sec == null)
			sec = curSection;
		if (sec < 0)
			sec = 0;

		if (SONG.notes[sec] == null)
			return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset)
		{
			endCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				endCallback();
			});
		}
	}

	public var transitioning = false;

	public function endSong()
	{
		songEndCallback();
		#if mobileC mobileControls.visible = false; #end
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					var hitThing = 0.05 * healthLoss;
					/*if(kr == health && curStage.endsWith("hall"))
						healthTween(-hitThing);
					else if(kr > health && curStage.endsWith("hall"))
						krChange(hitThing)
					else if(!curStage.contains("hall"))*/
						healthTween(-hitThing);
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					var hitThing = 0.05 * healthLoss;
					/*if(kr == health && curStage.endsWith("hall"))
						healthTween(-hitThing);
					else if(kr > health && curStage.endsWith("hall"))
						krChange(hitThing)
					else if(!curStage.contains("hall"))*/
						healthTween(-hitThing);
				}
			}

			if (doDeathCheck())
			{
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent))
				percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);
				if (SONG.song.toLowerCase() == 'sansational' && !attacked)
					storyPlaylist.push('final-stretch');

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					if(FlxG.save.data.instPrev == false)
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if (desktop && !hl) DiscordClient.resetClientID(); #end

					cancelMusicFadeTween();
					switchState(new StoryMenuState());

					// if ()
					if (ClientPrefs.getGameplaySetting('practice') && ClientPrefs.getGameplaySetting('botplay'))
					{
						// StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore('week' + storyWeek, campaignScore, storyDifficulty);

						// FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePathForStory(); // FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU FUCK YOU

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);
					Main.allowedToClear = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if (desktop && !hl) DiscordClient.resetClientID(); #end

				cancelMusicFadeTween();
				switchState(new FreeplayState());
				if(FlxG.save.data.instPrev == false)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;

	// Stores HUD Elements in a Group
	public var uiGroup:FlxSpriteGroup;

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				spr.destroy();
				comboGroup.remove(spr);
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			++daRating.hits;
		note.rating = daRating.name;
		score = daRating.score;

		if (daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				++songHits;
				++totalPlayed;
				RecalculateRating(false);
			}
		}

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage)
				uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		// let's not make this disabled by default
		if ((!ClientPrefs.data.lowQuality) || cpuControlled && ClientPrefs.data.lowQuality)
		{
			rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
			rating.screenCenter();
			rating.x = placement - 40;
			rating.y -= 60;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			rating.visible = (!ClientPrefs.data.hideHud && showRating);
			rating.x += ClientPrefs.data.comboOffset[0];
			rating.y -= ClientPrefs.data.comboOffset[1];
			rating.antialiasing = antialias;

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
			comboSpr.screenCenter();
			comboSpr.x = placement;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
			comboSpr.x += ClientPrefs.data.comboOffset[0];
			comboSpr.y -= ClientPrefs.data.comboOffset[1];
			comboSpr.antialiasing = antialias;
			comboSpr.y += 60;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboGroup.add(rating);

			if (!PlayState.isPixelStage)
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
			}

			comboSpr.updateHitbox();
			rating.updateHitbox();

			var seperatedScore:Array<Int> = [];

			if (combo >= 1000)
			{
				seperatedScore.push(Math.floor(combo / 1000) % 10);
			}
			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);
			seperatedScore.push(combo % 10);

			var daLoop:Int = 0;
			var xThing:Float = 0;
			if (showCombo)
				comboGroup.add(comboSpr);

			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
				numScore.screenCenter();
				numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
				numScore.y += 80 - ClientPrefs.data.comboOffset[3];

				if (!PlayState.isPixelStage)
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				else
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				numScore.visible = !ClientPrefs.data.hideHud;
				numScore.antialiasing = antialias;

				// if (combo >= 10 || combo == 0)
				if (showComboNum)
					comboGroup.add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002 / playbackRate
				});

				++daLoop;
				if (numScore.x > xThing)
					xThing = numScore.x;
			}
			comboSpr.x = xThing + 50;
			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			keyPressed(key);
	}

	private function keyPressed(key:Int)
	{
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			if (notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if (Conductor.songPosition >= 0)
					Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var sortedNotesList:Array<Note> = [];
				for (daNote in notes)
				{
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.exists
						&& daNote.canBeHit
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& !daNote.isSustainNote
						&& !daNote.blockHit)
					{
						if (daNote.noteData == key)
							sortedNotesList.push(daNote);
						canMiss = true;
					}
				}
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					var epicNote:Note = sortedNotesList[0];
					if (sortedNotesList.length > 1)
					{
						for (bad in 1...sortedNotesList.length)
						{
							var doubleNote:Note = sortedNotesList[bad];
							// no point in jack detection if it isn't a jack
							if (doubleNote.noteData != epicNote.noteData)
								break;

							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								notes.remove(doubleNote, true);
								doubleNote.destroy();
								break;
							}
							else if (doubleNote.strumTime < epicNote.strumTime)
							{
								// replace the note if its ahead of time
								epicNote = doubleNote;
								break;
							}
						}
					}

					// eee jack detection before was not super good
					goodNoteHit(epicNote);
				}
				else
				{
					callOnScripts('onGhostTap', [key]);
					if (canMiss && !boyfriend.stunned)
						noteMissPress(key);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				if (!keysPressed.contains(key))
					keysPressed.push(key);

				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyPress', [key]);
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && key > -1)
			keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if (!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if (key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if (pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			if (notes.length > 0)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.isSustainNote
						&& holdArray[daNote.noteData]
						&& daNote.canBeHit
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& !daNote.blockHit)
					{
						goodNoteHit(daNote);
					}
				});
			}

			if (!holdArray.contains(true) || endingSong)
			{
				if (boyfriend.animation.curAnim != null
					&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
						&& boyfriend.animation.curAnim.name.startsWith('sing')
						&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
				}
			}
			#if ACHIEVEMENTS_ALLOWED
			else
				checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if (releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
				{
				notes.remove(note, true);
				note.destroy();
			}
		});
		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote
		]);
		if (result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll)
			callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.data.ghostTapping)
			return; // fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = 0.05;
		if (note != null)
			subtract = note.missHealth;
		var hitThing = subtract * healthLoss;
		/*if(kr == health && curStage.endsWith("hall"))
			healthTween(-hitThing);
		else if(kr > health && curStage.endsWith("hall"))
			krChange(hitThing)
		else if(!curStage.contains("hall"))*/
			healthTween(-hitThing);

		switch (note.noteType)
				{
					case 'Orange Bone Notes':
							if ((SONG.song.toLowerCase() == 'sansational' && attacked) || (SONG.song.toLowerCase() != 'sansational') && mechsDifficulty != 0)
							{
								if(kr == health){
									healthTweenObj.cancel();
									health -= (mechsDifficulty == 2 ? 2 : 0.8);
								} else if(kr > health)
									krChange(mechsDifficulty == 2 ? 2 : 0.8);
							}
				}

		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		combo = 0;

		if (!practiceMode || SONG.song.toLowerCase() == 'sansational' && !attacked && note.noteType != 'Blue Bone Notes')
			songScore -= 10;
		if (!endingSong)
			++songMisses;
		++totalPlayed;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if ((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection))
			char = gf;

		if (char != null && char.hasMissAnimations)
		{
			var suffix:String = '';
			if (note != null)
				suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, direction)))] + 'miss' + suffix;
			if (!note.isSustainNote || char.animation.curAnim.name != animToPlay + note.animSuffix && !note.isSustainNote)
				char.playAnim(animToPlay, true);

			if (char != gf && combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		if (cpuControlled)
			cupheadPewMode = false;

		if (cupheadChaserMode && !note.isSustainNote)
		{
			var chaseOffset:Array<Int> = [0, 0];
			switch (note.noteData)
			{
				case 0:
					chaseOffset = [707, -19];
				case 1:
					chaseOffset = [817, -9];
				case 2:
					chaseOffset = [717, -19];
				case 3:
					chaseOffset = [847, 27];
			}
			chaseOffset[0] -= 140;
			var chaser:CupBullet = new CupBullet('chaser', dad.getMidpoint().x + 545, dad.getMidpoint().y - 75);
			// chaser.x += chaseOffset[0];
			// chaser.y += chaseOffset[1];
			add(chaser);
			chaser.blend = ADD;
			chaser.state = 'oneshoot';
			chaser.animation.finishCallback = function(name:String)
			{
				remove(chaser);
			};
			chaser.pew = function()
			{
				if(mechsDifficulty != 0)
					healthTween(-0.02);
			}
			FlxG.sound.play(Paths.sound('attacks/chaser' + FlxG.random.int(0, 4), 'cup'), 0.7);
		}

		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim
					&& !SONG.notes[curSection].gfSection
					|| (dad.curCharacter == 'cuphead-pissed' || dad.curCharacter == 'nigtmareCuphead')
					&& cupheadChaserMode)
				{
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + altAnim;
			if (note.gfNote)
			{
				char = gf;
			}

			if (char != null)
			{
				if (!note.isSustainNote || (char.animation.curAnim.name != animToPlay + note.animSuffix && !note.isSustainNote))
					char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		if (SONG.song.toLowerCase() == 'sansational' && !attacked && note.noteType == 'Blue Bone Notes' || mechsDifficulty == 0)
		{
			// nothing
		}
		else
		{
			strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		}
		note.hitByOpponent = true;

		var result:Dynamic = callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);
		if (result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll){
			callOnHScript('opponentNoteHit', [note]);
			stagesFunc(function(stage:BaseStage) stage.opponentNoteHit());
		}

		if (!note.isSustainNote)
		{
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			{
				if (cardfloat <= 200)
					cardtweening(1.75);
				else
				{
					if (poped)
					{
						trace('played pop anim');
						poped = false;
						cardanims.animation.play('pop');
						cardanims.alpha = 1;
						cardbar.alpha = 0;
					}
				}
			}
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;
			if (!note.isSustainNote)
			{
				if (ClientPrefs.data.hitsoundVolume > 0
					&& !note.hitsoundDisabled
					&& note.hitsound == 'hitsound'
					&& (note.hitsoundDirectory == '' || note.hitsoundDirectory == null))
					FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume).pan = note.noteData < 4 ? -0.3 : 0.3; // would be coolio;
				else
					FlxG.sound.play(Paths.sound(note.hitsound, note.hitsoundDirectory), 1).pan = note.noteData < 4 ? -0.3 : 0.3; // would be coolio;
			}
			switch (note.noteType)
			{
				case 'Parry':
					cardanims.animation.play('parry', true);
					cardfloat += 200;
			}
			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashData.disabled && !note.isSustainNote)
					if ((note.noteType == "Blue Bone Notes" && SONG.song.toLowerCase() == 'sansational' && attacked) || (note.noteType == "Blue Bone Notes" && SONG.song.toLowerCase() != 'sansational') ||  note.noteType != "Blue Bone Notes")
						spawnNoteSplashOnNote(note);

				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'blue Bone Notes':
							if ((SONG.song.toLowerCase() == 'sansational' && attacked) || (SONG.song.toLowerCase() != 'sansational') && mechsDifficulty != 0)
							{
								if(kr == health){
									healthTweenObj.cancel();
									health -= (mechsDifficulty == 2 ? 2 : 0.8);
								} else if(kr > health)
									krChange(mechsDifficulty == 2 ? 2 : 0.8);
							}
						case 'Hurt Note': // Hurt note
							if (boyfriend.animation.getByName('hurt') != null)
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}
			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if (note.gfNote)
				{
					if (gf != null)
					{
						if (!note.isSustainNote || gf.animation.curAnim.name != animToPlay + note.animSuffix && !note.isSustainNote)
							gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					if (!note.isSustainNote || (boyfriend.animation.curAnim.name != animToPlay + note.animSuffix && !note.isSustainNote))
					{
						boyfriend.playAnim(animToPlay + note.animSuffix, true);
						boyfriend.holdTimer = 0;
					}
				}

				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
			if (!note.isSustainNote && !cpuControlled)
			{
				songScore += 500 * Std.int(healthGain);
				++combo;
				if (combo > 9999)
					combo = 9999;
				popUpScore(note);
			}
			var hitThing = note.hitHealth * healthGain;
			healthTween(hitThing);
			if (curStage.endsWith("hall"))
				krTween(hitThing);
			if (cpuControlled)
			{
				var time:Float = 0.15 / playbackRate;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				if ((note.noteType == "Blue Bone Notes" && SONG.song.toLowerCase() == 'sansational' && attacked) || (note.noteType == "Blue Bone Notes" && SONG.song.toLowerCase() != 'sansational') ||  note.noteType != "Blue Bone Notes")
					strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			}
			else
			{
				var spr = playerStrums.members[note.noteData];
				if (spr != null)
				{
					if ((note.noteType == "Blue Bone Notes" && SONG.song.toLowerCase() == 'sansational' && attacked) || (note.noteType == "Blue Bone Notes" && SONG.song.toLowerCase() != 'sansational') ||  note.noteType != "Blue Bone Notes")
						spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
			if (result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll)
				callOnHScript('goodNoteHit', [note]);

			if (!note.isSustainNote)
			{
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy()
	{
		FlxG.game.filtersEnabled = false;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if (script != null)
			{
				script.call('onDestroy');
				script.kill();
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		// Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		instance = null;
		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		if (FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if (curStep == lastStepHit)
		{
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		if (FlxG.camera.zoom < 1.35 && !utMode && (curBeat % bumpRate == 0))
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
			gf.dance();
		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();
		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
			dad.dance();

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				if (!utmode)
					moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad))
			luaToLoad = SUtil.getPath() + Paths.getPreloadPath(luaFile);

		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if (OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if (script.scriptName == luaToLoad)
					return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(scriptFile);

		if (FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad))
				return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var newScript:HScript = new HScript(null, file);
			if (newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.kill();
				return;
			}

			hscriptArray.push(newScript);
			if (newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);

					newScript.kill();
					hscriptArray.remove(newScript);
					trace('failed to initialize tea interp!!! ($file)');
				}
				else
					trace('initialized tea interp successfully: $file');
			}
		}
		catch (e)
		{
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			var newScript:HScript = cast(SScript.global.get(file), HScript);
			if (newScript != null)
			{
				newScript.kill();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [psychlua.FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result))
			result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while (i < len)
		{
			var script:FunkinLua = luaArray[i];
			if (exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if ((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if (!script.closed)
				i++;
			else
				len--;
		}
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = new Array();
		if (excludeValues == null)
			excludeValues = new Array();
		excludeValues.push(psychlua.FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for (i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
						FunkinLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n') + 1), true,
							false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if ((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll)
						&& !excludeValues.contains(myValue)
						&& !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if (myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null)
			exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin))
				continue;

			if (!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = opponentStrums.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false)
	{
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if (ret != FunkinLua.Function_Stop)
		{
			ratingName = '?';
			if (totalPlayed != 0) // Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				if (ratingPercent < 1)
					for (i in 0...ratingStuff.length - 1)
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	function fullComboUpdate()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = 'Clear';
		if (songMisses < 1)
		{
			if (bads > 0 || shits > 0)
				ratingFC = 'FC';
			else if (goods > 0)
				ratingFC = 'GFC';
			else if (sicks > 0)
				ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if (chartingMode)
			return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if (cpuControlled)
			return;

		for (name in achievesToCheck)
		{
			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				switch (name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					case 'debugger':
						unlock = (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice);
				}
			}
			else
			{
				if (isStoryMode
					&& campaignMisses + songMisses < 1
					&& Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1
					&& !changedDifficulty
					&& !usedPractice)
					unlock = true;
			}

			if (unlock)
				Achievements.unlockAchievement(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if (!ClientPrefs.data.shaders)
			return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if (!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for (mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else
					frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else
					vert = null;

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end

	function addSansBar()
	{
		// health bar color
		sansColors = true;
		healthBar.leftToRight = true;

		// hp thing
		hpTxt = new FlxSprite(healthBar.x - 40, healthBar.y - 5).loadGraphic(Paths.image('HPtext'));
		uiGroup.add(hpTxt);

		// karma health swag
		var thing = healthBar.rightBar;
		uiGroup.remove(healthBar.rightBar);
		krBar = new FlxBar(healthBar.x, healthBar.y, LEFT_TO_RIGHT, Std.int(healthBar.bg.width), Std.int(healthBar.bg.height), this, 'kr', 0,2); 
		krBar.createFilledBar(FlxColor.TRANSPARENT, 0xFFff00ff);
		uiGroup.add(krBar);
		//krBar.y += 3;
		uiGroup.add(healthBar.leftBar);
		healthBar.rightBar = thing;

		// resizing
		healthBar.scale.x = 0.95;
		healthBar.scale.y = 2;
		krBar.scale.x = 0.9395;
		krBar.scale.y = 1.410;

		//settings
		hpTxt.alpha = krBar.alpha = ClientPrefs.data.healthBarAlpha;
		hpTxt.visible = krBar.visible = !ClientPrefs.data.hideHud;
		iconP1.visible = iconP2.visible = healthBar.bg.visible = false;
	}

	function healthTween(amt:Float)
	{
		if(((kr >= health && amt > 0 || kr == health) && curStage.endsWith("hall")) || !curStage.contains("hall")) {
			healthTweenObj.cancel();
			healthTweenObj = FlxTween.num(health, health + amt, 0.1, {ease: FlxEase.cubeInOut}, function(v:Float)
			{
			health = v;
			if(curStage.endsWith("hall"))
				updatesansbars();
			});
		} else if(kr > health && curStage.endsWith("hall") && amt < 0) {
			healthTweenObj.cancel();
			krChange(Math.abs(amt));
			updatesansbars();
		}
	}

	public function addChromaticAbberation(value:Float = 0)
	{
		filters.push(chromaticAberration);
		// chromVal = value;
	}

	public function brightSetup()
	{
		if (curStage == 'factory' && (!FlxG.save.data.photosensitive && ClientPrefs.data.antialiasing))
		{
			defaultBrightVal = -0.05;
			brightSpeed = 0.2;
			brightMagnitude = 0.05;
			if (SONG.song.toLowerCase() == 'ritual')
			{
				defaultBrightVal = -0.05;
				brightSpeed = 0.5;
				brightMagnitude = 0.05;
			}
			else
			{
				if (SONG.song.toLowerCase() == 'nightmare-run')
				{
					defaultBrightVal = -0.05;
					brightSpeed = 0.5;
					brightMagnitude = 0.05;
				}
				else if (SONG.song.toLowerCase() == 'imminent-demise')
				{
					defaultBrightVal = 0;
				}
				else
				{
					defaultBrightVal = -0.05;
					brightSpeed = 0.5;
					brightMagnitude = 0.05;
				}
			}
		}
		if (SONG.song.toLowerCase() == 'devils-gambit')
		{
			defaultBrightVal = -0.05;
			brightSpeed = 0.2;
			brightMagnitude = 0.05;
		}
		else if (SONG.song.toLowerCase() == 'burning-in-hell')
		{
			defaultBrightVal = -0.12;
			brightSpeed = 0.1;
			brightMagnitude = 0.14;
		}
		else
		{
			defaultBrightVal = 0;
		}
	}

	public function sansAttack(type:AttackModes)
	{
		if(mechsDifficulty != 0) {
		var dodgedBlue = false;
		canPause = false;
		pressedSpace = false;
		canPressSpace = true;

		var waitTime:Float = 1;
		switch(type){
			case BONES:
				FlxG.sound.play(Paths.sound('notice', 'sans'), 0.6);
				alarm.alpha = 1;
				alarm.animation.play('play', true);
			case BLUE_BONES:
				FlxG.sound.play(Paths.sound('notice', 'sans'), 0.6);
				alarmbone.alpha = 1;
				alarmbone.animation.play('playblue', true);
			case ORANGE_BONES:
				FlxG.sound.play(Paths.sound('notice', 'sans'), 0.6);
				alarmbone.alpha = 1;
				alarmbone.animation.play('playorange', true);
			default:
				trace('nuh uh');
		}
		waitTime = Conductor.crochet / 500;
		moveCamera(false);

		var dietimer = new FlxTimer().start(waitTime, function(tmr:FlxTimer)
		{
			switch(type) {
				case BONES:
					alarm.alpha = 1.0;
					alarm.animation.play('DIE', true);
					FlxG.sound.play(Paths.sound('sansattack', 'sans'));
					alarm.animation.finishCallback = function(name:String) {
						alarm.alpha = 0.0001;
						canPause = true;
					}
				case BLUE_BONES:
					if(!dodgedBlue){
					alarmbone.alpha = 1;
					alarmbone.animation.play('blue', true);
					FlxG.sound.play(Paths.sound('sansattack', 'sans'));
					alarmbone.animation.finishCallback = function(name:String)
					{
						alarmbone.alpha = 0.0001;
						canPause = true;
					}
				}
				case ORANGE_BONES:
					alarmbone.alpha = 1.0;
					alarmbone.animation.play('orange', true);
					FlxG.sound.play(Paths.sound('sansattack', 'sans'));
					alarmbone.animation.finishCallback = function(name:String){
						alarmbone.alpha = 0.0001;
						canPause = true;
					}
				default:
					trace('nuh uh');
		}

			if (pressedSpace || cpuControlled)
			{
				FlxG.sound.play(Paths.sound('dodge', 'sans'));
				chromVal = 0.03;
				FlxTween.tween(this, {chromVal: 0}, 0.3);
				if(type != BLUE_BONES){
				
				// bf dodge sprite
				if (bfDodge != null)
				{
					bfDodge.alpha = 1;
					bfDodge.animation.play('Dodge', true);
					boyfriend.alpha = 0.0001;
					bfDodge.animation.finishCallback = function(name:String)
					{
						bfDodge.alpha = 0.0001;
						boyfriend.alpha = 1;
					}
				} else {

					//animation
					if (boyfriend.animation.getByName('dodge') != null) {
					boyfriend.playAnim('dodge', true);
					} else {
					boyfriend.playAnim('singUP', true);
					}
					boyfriend.specialAnim = true;
					}

					// blue bones shit
				} else if(type == BLUE_BONES && !cpuControlled){
					dodgedBlue = true;
					alarmbone.alpha = 1.0;
					alarmbone.animation.play('blue', true);
					FlxG.sound.play(Paths.sound('sansattack', 'sans'));
					alarmbone.animation.finishCallback = function(name:String)
					{
						alarmbone.alpha = 0.0001;
						canPause = true;
					}
					if(kr == health){
						healthTweenObj.cancel();
						health -= (mechsDifficulty == 2 ? 2 : 0.8);
					} else if(kr > health)
						krChange(mechsDifficulty == 2 ? 2 : 0.8);
						boyfriend.playAnim('singUPmiss', true);
						boyfriend.specialAnim = true;
				}
			} else {
				if(type != BLUE_BONES){
				if(kr == health){
					healthTweenObj.cancel();
					health -= (mechsDifficulty == 2 ? 2 : 0.8);
				} else if(kr > health)
					krChange(mechsDifficulty == 2 ? 2 : 0.8);
				}
			}
			FlxG.camera.shake(0.005);
			canPressSpace = false;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				if (alarmbone != null)
					alarmbone.alpha = 0.0001;
				if (alarm != null)
					alarm.alpha = 0.0001;
				});
			});
		}
	}

	public function attackCheck(type:AttackModes)
	{
		switch (type)
		{
			case SANS:
				if ((controls.justPressed('attack') && attackHud.alpha > 0.001) && attackCooldown == 0 && !cpuControlled && !inCutscene)
				{
					attackCooldown = 5;
					boyfriend.playAnim('attack', true);
					boyfriend.specialAnim = true;

					FlxG.sound.play(Paths.sound('Throw' + FlxG.random.int(1, 3), 'sans'));

					if (bfDodge != null)
					{
						bfDodge.alpha = 0.0001;
						boyfriend.alpha = 1;
					}

					new FlxTimer().start(0.375, function(tmr:FlxTimer)
					{
						dad.playAnim('dodge', true);
						dad.specialAnim = true;
						FlxG.sound.play(Paths.sound('dodge', 'sans'), 0.6);
						if (SONG.song.toLowerCase() == 'sansational' && !attacked)
						{
							attacked = true;
							storyPlaylist.push('burning-in-hell');
							changeNoteSkin();
						}
						healthTween(0.2);
						FlxG.camera.shake(0.005);
						chromVal = 0.03;
						FlxTween.tween(this, {chromVal: 0}, 0.3);
					});
				}
			case PEA:
				if (controls.justPressed('attack'))
				{
					trace(cardfloat);
					if (cardfloat >= 200)
					{
						attackHud.useHUD();
						cardfloat = 0;
						poped = true;
						cardanims.animation.play('use', true);
						cupheadPewMode = false;
						pewdmgScale = 1.0;
						cardanims.animation.finishCallback = function(use)
						{
							didntdoanimyet = true;
							cardbar.alpha = 1;
							if (cardfloat < 200)
								cardanims.alpha = 0.0001;
						}

						new FlxTimer().start(0.3, function(tmr:FlxTimer)
						{
							chromVal = 0.008;
							FlxTween.tween(this, {chromVal: 0.002}, 0.3);
							dad.specialAnim = false;
							dad.playAnim('hit', true);
							dad.specialAnim = true;
							FlxG.sound.play(Paths.sound('hurt', 'cup'), 0.5);
							healthTween(0.5);
							pewhits = 0;
							switch (SONG.song.toLowerCase())
							{
								case 'technicolor-tussle':
									pewdmg = 0.0225;

								case 'knockout':
									pewdmg = 0.0475;

								case 'devils-gambit':
									pewdmg = 0.075;
							}
						});

						boyfriend.playAnim('attack', true);
						boyfriend.specialAnim = true;
					}
				}
			default:
				trace('undfined');
		}
	}

	function changeNoteSkin()
	{
		for (note in unspawnNotes)
		{
			if (note.noteType == 'Orange Bone Notes')
			{
				note.texture = 'noteSkins/OBONE_assets';
				note.noteSplashData.texture = 'noteSplashes/noteSplashes-OBone';
				//note.missHealth = mechsDifficulty == 2 ? 0 : 0.8;
			}
			if (note.noteType == 'Blue Bone Notes')
			{
				note.texture = 'noteSkins/BBONE_assets';
				note.noteSplashData.texture = 'noteSplashes/noteSplashes-BBone';
			}
		}
	}

	public function checkBlasters(elapsed:Float)
	{
		if (utmode && soul != null)
		{
			blaster.forEachAlive(function(bull:FlxSprite)
			{
				if (soul.overlaps(bull) && bull.alpha == 1)
				{
					bull.animation.callback = function(boom, frameNumber:Int, frameIndex:Int)
					{
						if (frameNumber >= 28)
						{
							var hitboxRect = new backend.AdvancedRect(bull.x, bull.y + 100, bull.width, bull.height + 25);
							var rotatedRect = hitboxRect.getTheRotatedBounds(bull.angle);
							rotatedRect.width = hitboxRect.width;
							rotatedRect.height = hitboxRect.height;
							if (soul.isInside(rotatedRect))
							{
								if (!cpuControlled)
								{
									gethurt();
								}
							}
						}
					}
				}
			});

			var ups:Bool = false;
			var downs:Bool = false;
			var lefts:Bool = false;
			var rights:Bool = false;

			ups = controls.NOTE_UP;
			downs = controls.NOTE_DOWN;
			lefts = controls.NOTE_LEFT;
			rights = controls.NOTE_RIGHT;

			if (ups && downs)
				ups = downs = false;
			if (lefts && rights)
				lefts = rights = false;

			if (ups || downs || lefts || rights)
			{
				if (ups)
				{
					soul.y -= 650 * elapsed;
					if (!soul.isInside(Hall.battleBoundaries))
					{
						trace('cantgo');
						soul.y += 650 * elapsed;
					}
				}
				if (downs)
				{
					soul.y += 650 * elapsed;
					if (!soul.isInside(Hall.battleBoundaries))
					{
						trace('cantgo');
						soul.y -= 650 * elapsed;
					}
				}
				if (lefts)
				{
					soul.x -= 650 * elapsed;
					if (!soul.isInside(Hall.battleBoundaries))
					{
						trace('cantgo');
						soul.x += 650 * elapsed;
					}
				}
				if (rights)
				{
					soul.x += 650 * elapsed;
					if (!soul.isInside(Hall.battleBoundaries))
					{
						trace('cantgo');
						soul.x -= 650 * elapsed;
					}
				}
			}
		}
	}

	public function gethurt()
	{
		if (cangethurt)
		{
			//health -= mechsDifficulty == 2 ? 1 : 0.8;
			//healthTween(mechsDifficulty == 2 ? -1 : -0.8);
			if(kr == health){
				healthTweenObj.cancel();
				health -= (mechsDifficulty == 2 ? 1 : 0.8);
			} else if(kr > health)
				krChange(mechsDifficulty == 2 ? 1 : 0.8);
			cangethurt = false;
			FlxG.sound.play(Paths.sound('hurt', 'sans'));
			flixel.effects.FlxFlicker.flicker(soul, 1.5, 0.1, true);
			new FlxTimer().start(1.5, function(tmr:FlxTimer)
			{
				cangethurt = true;
			}, 1);
		}
	}

	public function doutshit()
	{
		FlxTween.tween(soul, {alpha: 1}, 0.5);
		FlxTween.tween(boyfriend, {alpha: 0.5}, 0.5);
		utmode = true;
		boyfriend.stunned = true;
		moveCamera(false);
	}

	public function dontutshit()
	{
		FlxTween.tween(soul, {alpha: 0}, 0.5);
		FlxTween.tween(boyfriend, {alpha: 1}, 0.5);
		utmode = false;
		boyfriend.stunned = false;
	}

	public function blastem(killme:Float)
	{
		var pointAt:lime.math.Vector2 = new lime.math.Vector2(soul.x, soul.y);

		FlxG.sound.play(Paths.sound('readygas', 'sans'));

		var gay:FlxSprite = new FlxSprite(Hall.battleBG.x - 2450, soul.y - 150);
		gay.frames = Paths.getSparrowAtlas("Gaster_blasterss", "sans");
		gay.animation.addByPrefix('boom', 'fefe instance', 27, false);
		gay.animation.play('boom');
		gay.antialiasing = ClientPrefs.data.antialiasing;
		gay.flipX = FlxG.random.bool();
		blaster.add(gay);
		gay.alpha = 0.999999;

		gay.height = gay.height * 0.8;

		var homo = 180 / Math.PI * (Math.atan(findSlope(gay.x, gay.y, pointAt.x, pointAt.y)));
		gay.angle = homo;
		gay.y += homo * 2;

		gay.animation.callback = function(boom, frameNumber:Int, frameIndex:Int)
		{
			if (frameNumber == 28)
			{
				gay.alpha = 1;
				FlxG.sound.play(Paths.sound('shootgas', 'sans'));
				FlxG.camera.shake(0.015, 0.1);
				camHUD.shake(0.005, 0.1);

				chromVal = 0.04;
				FlxTween.tween(this, {chromVal: 0}, FlxG.random.float(0.05, 0.12));

				for (i in playerStrums)
				{
					if (i.angle == 0)
					{
						var baseX:Float = i.x;
						var baseY:Float = i.y;
						var baseA:Float = i.angle;
						var randox = if (FlxG.random.bool()) FlxG.random.float(-30, -15); else FlxG.random.float(30, 15);
						var randoy = if (FlxG.random.bool()) FlxG.random.float(-30, -15); else FlxG.random.float(30, 15);
						var randoa = if (FlxG.random.bool()) FlxG.random.float(-45, -15); else FlxG.random.float(45, 15);
						i.x += randox;
						i.y += randoy;
						i.angle += randoa;
						FlxTween.tween(i, {x: baseX, y: baseY, angle: baseA}, 0.4, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								i.x = baseX;
								i.y = baseY;
								i.angle = baseA;
							}
						});
					}
				}
			}
		}
		gay.animation.finishCallback = function(boom)
		{
			gay.kill();
		}
	}

	function findSlope(x0:Float, y0:Float, x1:Float, y1:Float)
	{
		return (y1 - y0) / (x1 - x0);
	}

	function shootOnce(isNightmare:Bool = false)
	{
		var cupheadPewThing = new CupBullet('pewFX', dad.getMidpoint().x + 90, dad.getMidpoint().y - 90);
		if (dad.curCharacter == 'cuphead-pissed')
		{
			cupheadPewThing.x += 80;
			cupheadPewThing.y -= 25;
		}
		if (dad.curCharacter != 'cupheadNightmare')
		{
			cupheadPewThing.state = 'oneshoot';
			add(cupheadPewThing);

			cupheadPewThing.animation.finishCallback = function(name:String)
			{
				remove(cupheadPewThing);
			};
		}
		var chaseOffset = [670, -105];
		if (dad.curCharacter == 'cuphead-pissed')
			chaseOffset = [645, -125];

		var pew:String = 'pew';
		if (isNightmare)
		{
			pew = 'laser';
			chaseOffset = [700, 270];
		}
		var cupheadShot = new CupBullet(pew, dad.getMidpoint().x + chaseOffset[0], dad.getMidpoint().y + chaseOffset[1]);
		if (dad.curCharacter == 'cupheadNightmare')
		{
			cupheadShot.x += 300;
			cupheadShot.y += 100;

			FlxG.sound.play(Paths.sound('attacks/pea' + FlxG.random.int(0, 5), 'cup'), 0.4);
		}
		else
		{
			FlxG.sound.play(Paths.sound('attacks/pea' + FlxG.random.int(0, 5), 'cup'), 0.6);
		}

		add(cupheadShot);
		cupheadShot.state = 'oneshoot';

		switch (SONG.song.toLowerCase())
		{
			case 'knockout':
				pewdmg = 0.0475;

			case 'devils-gambit':
				pewdmg = 0.075;

			case 'technicolor-tussle':
				pewdmg = 0.0120;
				cupheadPewThing.x -= 100;
				cupheadShot.x -= 100;
		}

		if (pewhits >= 10
			&& SONG.song.toLowerCase() != 'technicolor-tussle'
			&& cupheadPewMode) // to keep people from passing the bullet sections without dying
		{
			pewdmgScale += 0.15;
			if (SONG.song.toLowerCase() == 'devils-gambit')
				pewdmgScale += 0.05;
			pewdmg *= pewdmgScale;
		}
		else if (pewhits > 15 && SONG.song.toLowerCase() == 'technicolor-tussle' && cupheadPewMode)
		{
			pewdmgScale += 0.01;
			pewdmg *= pewdmgScale;
		}

		cupheadShot.pew = function()
		{
			if (!cpuControlled)
			{
				healthTween(-pewdmg);
				++pewhits;
			}
		};

		cupheadShot.animation.finishCallback = function(name:String)
		{
			remove(cupheadShot);
		};
	}

	public function startCupheadShoot()
	{
		if (!dad.animation.curAnim.name.contains('hit'))
		{
			cupheadPewMode = true;
			dad.playAnim('attack', true);
			dad.specialAnim = true;
		}
	}

	function cardtweening(amt:Float)
	{
		if (SONG.song.toLowerCase() != 'snake-eyes')
		{
			if (cardtween != null)
				cardtween.cancel();
			cardtween = FlxTween.num(cardfloat, cardfloat + amt, 0.001, {ease: FlxEase.cubeInOut}, function(v:Float)
			{
				cardfloat = v;
			});
		}
	}

	public function cupheadDodge(type:AttackModes)
	{
		if(mechsDifficulty != 0) {
		canPause = false;
		pressedSpace = false;
		canPressSpace = true;
		var waitTime:Float = 0.7;
		var shootWait:Float = 0.5;
		var typeString:String = 'null';
		switch (type)
		{
			case ROUNDABOUT:
				typeString = 'ROUNDABOUT';
				typeString = typeString.toLowerCase();
				var killme = [boyfriend.x, boyfriend.y];
				var fuckme = [cupBullets[1].x, cupBullets[1].y];
				boyfriendGroup.remove(boyfriend);
				boyfriendGroup.remove(cupBullets[1]);
				boyfriendGroup.add(cupBullets[1]);
				cupBullets[1].x = fuckme[0];
				cupBullets[1].y = fuckme[1];
				boyfriendGroup.add(boyfriend);
				boyfriend.x = killme[0];
				boyfriend.y = killme[1];
				shootWait = 0.5;
				dad.playAnim('attackR', true);
				dad.specialAnim = true;
				FlxG.sound.play(Paths.sound('shoot', 'cup'));
				new FlxTimer().start(shootWait, function(tmr:FlxTimer)
				{
					var killme = [boyfriend.x, boyfriend.y];
					var fuckme = [cupBullets[1].x, cupBullets[1].y];
					boyfriendGroup.remove(boyfriend);
					boyfriendGroup.remove(cupBullets[1]);
					boyfriendGroup.add(boyfriend);
					boyfriend.x = killme[0];
					boyfriend.y = killme[1];
					boyfriendGroup.add(cupBullets[1]);
					cupBullets[1].x = fuckme[0];
					cupBullets[1].y = fuckme[1];
					var waitTime2 = 0.9 + shootWait;
					var dietimer2 = new FlxTimer().start(waitTime2, function(tmr:FlxTimer)
					{
						moveCamera(false);
						trace('roundabout went back');
						if ((canPressSpace && pressedSpace) || cpuControlled)
						{
							FlxG.sound.play(Paths.sound('dodge', 'cup'));
							boyfriend.playAnim('dodge', true);
							boyfriend.specialAnim = true;
							boyfriend.alpha = 1;
							pressedSpace = false;
						}
						else
						{
							healthTweenObj.cancel();
							if(mechsDifficulty == 1){
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
							FlxG.sound.play(Paths.sound('hurt', 'cup'), 0.5);
							}
							health -= mechsDifficulty == 2 ? 2 : 1.6;
						}
						canPressSpace = false;
						canPause = true;
					});
				});
			case HADOKEN:
				typeString = 'HADOKEN';
				typeString = typeString.toLowerCase(); // lazyness at it's peak
				if (SONG.song.toLowerCase() == 'devils-gambit')
				{
					FlxG.sound.play(Paths.sound('pre_shoot', 'cup'), 1);
				}
				dad.playAnim('attackH', true);
				dad.specialAnim = true;
			default:
				trace('undfined');
		}

		var cuptimer = new FlxTimer().start(shootWait, function(tmr:FlxTimer)
		{
			for (i in 0...cupBullets.length)
			{
				if (cupBullets[i].bType == typeString)
				{
					cupBullets[i].x = dad.getMidpoint().x;
					cupBullets[i].y = dad.getMidpoint().y;
					if (SONG.song.toLowerCase() == 'devils-gambit')
					{
						cupBullets[i].x = dad.getMidpoint().x - 200;
						cupBullets[i].y = dad.getMidpoint().y + 400;
					}
					cupBullets[i].state = 'shoot';
					cupBullets[i].time = 0;
					cupBullets[i].hsp = 0;
					cupBullets[i].vsp = 0;
					var defaultChrom = chromVal;
					chromVal = 0.04;
					FlxTween.tween(this, {chromVal: defaultChrom}, 0.3);
				}
			}
		});

		var dietimer = new FlxTimer().start(waitTime, function(tmr:FlxTimer)
		{
			moveCamera(false);
			if ((canPressSpace && pressedSpace) || cpuControlled)
			{
				pressedSpace = false;
				FlxG.sound.play(Paths.sound('dodge', 'cup'));
				boyfriend.playAnim('dodge', true);
				boyfriend.specialAnim = true;
				boyfriend.alpha = 1;
			}
			else
			{
				if(mechsDifficulty == 1){
					boyfriend.playAnim('hurt', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('hurt', 'cup'), 0.5);
					}
				healthTweenObj.cancel();
				health -= mechsDifficulty == 2 ? 2 : 1.6;
			}
			if (type != ROUNDABOUT)
			{
				canPressSpace = false;
				canPause = true;
			}
		});
		}
	}

	public static function switchState(nextState:flixel.FlxState = null){
		if(curStage == 'field'){
			Field.cupteaBackout();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			var killme = new FlxTimer().start(0.7, function(tmr:FlxTimer)
				{
				trace('fnished song');
				MusicBeatState.switchState(nextState);
				});
		} else
		MusicBeatState.switchState(nextState);
	}

	public function krTween(amt:Float) {
		if (health <= 0)
			amt = Math.abs(amt);
		krTweenObj.cancel();
		krTweenObj = FlxTween.num(kr, kr - amt, 0.1, {ease: FlxEase.cubeInOut}, function(v:Float)
		{
			kr = v;
			updatesansbars();
		});
	}

	public function krChange(amt:Float, force:Bool = false) {

		if (health <= 0)
		{
			amt = Math.abs(amt);
		}
		
		if (krTweenObj!=null)
			krTweenObj.cancel();

		if (force)
			kr = amt;
		else
			kr -= amt;

		updatesansbars();
	}

	function updatesansbars() {
		if (kr > health && hpTxt != null)
			hpTxt.color = 0xFFff00ff;
		if (kr <= health) {
			if(hpTxt != null)
			hpTxt.color = FlxColor.WHITE;
			kr = health;
		}
		if (kr>2)
			kr = 2;
	}
}
enum AttackModes
{
	SANS;
	BONES;
	BLUE_BONES;
	ORANGE_BONES;
	PEA;
	HADOKEN;
	ROUNDABOUT;
}