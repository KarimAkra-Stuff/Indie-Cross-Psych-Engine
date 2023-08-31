package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import shaders.WhiteOverlayShader;

using StringTools;

class FreeplaySelectState extends MusicBeatState
{
	public static var curSelected:Int = 0;
	public static var optionShit:Array<String> = ['story', 'bonus', 'nightmare'];
	var menuItems:FlxTypedGroup<FlxSprite>;
	var bg:FlxSprite;	

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("Selecting FreePlay", null);
		#end

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		generateButtons(332);

		changeItem();

		#if mobileC
		addVirtualPad(LEFT_RIGHT, A_B);
		#end

		super.create();
	}
	
	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		var selectedButton:FlxSprite = menuItems.members[curSelected];
		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			for (i in 0...optionShit.length){
				if (i == curSelected)
					menuItems.members[i].alpha = 1;
				else
					menuItems.members[i].alpha = 0.5;

			}
			if (controls.ACCEPT)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedButton.shader = new WhiteOverlayShader();
				selectedButton.shader.data.progress.value = [1.0];
				FlxTween.num(1.0, 0.0, 1.0, {ease: FlxEase.cubeOut}, function(num:Float)
				{
					selectedButton.shader.data.progress.value = [num];
				});
				new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						MusicBeatState.switchState(new states.FreeplayState());
					});
				}
			}

		super.update(elapsed);
	}
//i just cant fucking get the X and Y so i copy the way the sprites are added from original source
	function generateButtons(sep:Float)
		{
			if (menuItems == null)
				return;
	
			if (menuItems.members != null && menuItems.members.length > 0)
				menuItems.forEach(function(_:FlxSprite) {menuItems.remove(_); _.destroy(); } );
			
			for (i in 0...optionShit.length)
			{	
				var str:String = optionShit[i];
	
				var freeplayItem:FlxSprite = new FlxSprite();
				freeplayItem.loadGraphic(Paths.image('freeplayselect/' + str));
				freeplayItem.origin.set();
				freeplayItem.scale.set(MainMenuState.fuckersScale, MainMenuState.fuckersScale);
				freeplayItem.updateHitbox();
				freeplayItem.alpha = 0.5;
				freeplayItem.setPosition(120 + (i * sep), 20);
				
				menuItems.add(freeplayItem);
			}
		}
	
	public function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;	
	}
}