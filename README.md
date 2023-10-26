# Friday Night Funkin' - Psych Engine Mobile

Engine originally used on [Mind Games Mod](https://gamebanana.com/mods/301107), intended to be a fix for the vanilla version's many issues while keeping the casual play aspect of it. Also aiming to be an easier alternative to newbie coders.

> **Note**
> There may be bugs with the bleeding edge versions/nightly builds, and if so, do report them on the issue tracker.

## Indie Cross Psych Engine
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding
* Karim - Coding

## Mobile Credits:
* Lily - Head Porter
* Karim - Assistant Porter/Helper #1
* Hoovy - Helper #2

### Mobile Special Thanks
* Mihai Alexandru - Author of mobile controls and also his new storage stuff and FlxRuntimeShader is used here
* Hiho2950 - Optimizing Notes and Botplay (https://github.com/MobilePorting/FNF-PsychEngine-Mobile/pull/16)

## Psych Credits:
* Shadow Mario - Programmer
* RiverOaken - Artist
* Yoshubs - Assistant Programmer

### Psych Special Thanks
* bbpanzu - Ex-Programmer
* Yoshubs - New Input System
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks
_____________________________________

# Features

## Attractive animated dialogue boxes:

![](https://user-images.githubusercontent.com/44785097/127706669-71cd5cdb-5c2a-4ecc-871b-98a276ae8070.gif)


## Mod Support
* Probably one of the main points of this engine, you can code in .lua files outside of the source code, making your own weeks without even messing with the source!
* Comes with a Mod Organizing/Disabling Menu.


## Atleast one change to every week:
### Week 1:
  * New Dad Left sing sprite
  * Unused stage lights are now used
  * Dad Battle has a spotlight effect for the breakdown
### Week 2:
  * Both BF and Skid & Pump does "Hey!" animations
  * Thunders does a quick light flash and zooms the camera in slightly
  * Added a quick transition/cutscene to Monster
### Week 3:
  * BF does "Hey!" during Philly Nice
  * Blammed has a cool new colors flash during that sick part of the song
### Week 4:
  * Better hair physics for Mom/Boyfriend (Maybe even slightly better than Week 7's :eyes:)
  * Henchmen die during all songs. Yeah :(
### Week 5:
  * Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog
  * On Winter Horrorland, GF bops her head slower in some parts of the song.
### Week 6:
  * On Thorns, the HUD is hidden during the cutscene
  * Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental

## Cool new Chart Editor changes and countless bug fixes
![](https://github.com/ShadowMario/FNF-PsychEngine/blob/main/docs/img/chart.png?raw=true)
* You can now chart "Event" notes, which are bookmarks that trigger specific actions that usually were hardcoded on the vanilla version of the game.
* Your song's BPM can now have decimal values
* You can manually adjust a Note's strum time if you're really going for milisecond precision
* You can change a note's type on the Editor, it comes with five example types:
  * Alt Animation: Forces an alt animation to play, useful for songs like Ugh/Stress
  * Hey: Forces a "Hey" animation instead of the base Sing animation, if Boyfriend hits this note, Girlfriend will do a "Hey!" too.
  * Hurt Notes: If Boyfriend hits this note, he plays a miss animation and loses some health.
  * GF Sing: Rather than the character hitting the note and singing, Girlfriend sings instead.
  * No Animation: Character just hits the note, no animation plays.

## Multiple editors to assist you in making your own Mod
![Screenshot_3](https://user-images.githubusercontent.com/44785097/144629914-1fe55999-2f18-4cc1-bc70-afe616d74ae5.png)
* Working both for Source code modding and Downloaded builds!

## Story mode menu rework:
![](https://i.imgur.com/UB2EKpV.png)
* Added a different BG to every song (less Tutorial)
* All menu characters are now in individual spritesheets, makes modding it easier.

## Credits menu
![Screenshot_1](https://user-images.githubusercontent.com/44785097/144632635-f263fb22-b879-4d6b-96d6-865e9562b907.png)
* You can add a head icon, name, description and a Redirect link for when the player presses Enter while the item is currently selected.

## Awards/Achievements
* The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx)

## Options menu:
* You can change Note colors, Delay and Combo Offset, Controls and Preferences there.
 * On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc.

## Other gameplay features:
* When the enemy hits a note, their strum note also glows.
* Lag doesn't impact the camera movement and player icon scaling anymore.
* Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes)
* You can reset your Score on Freeplay/Story Mode by pressing Reset button.
* You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space.
* You can enable "Combo Stacking" in Gameplay Options. This causes the combo sprites to just be one sprite with an animation rather than sprites spawning each note hit.


# Friday Night Funkin': Indie Cross
## About
FNF: Indie Cross is a massive community collaboration with the goal of bringing together an ultimate rhythm gaming experience

# Credits
### Team Credits in-game

### Friday Night Funkin'
 - [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programming
 - [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
 - [Kawai Sprite](https://twitter.com/kawaisprite) - Music

This game was made with love to Newgrounds and its community. Extra love to Tom Fulp.'

### Bendy and the Ink Machine
 - [Joey Drew Studios](https://twitter.com/joeydrewstu)

### Cuphead
 - [Studio MDHR](https://twitter.com/studiomdhr)

### Undertale
 - [Toby Fox](https://twitter.com/tobyfox)

### Untitled Goose Game
 - [House House](https://twitter.com/house_house_)

### Adobe Animate CC - Texture Atlas for OpenFL
 - [mathieuanthoine](https://github.com/mathieuanthoine)


# Installation
1. [Install Haxe 4.2.5](https://haxe.org/download)
2. Install `git`.
	- Windows: install from the [git-scm](https://git-scm.com/downloads) website.
	- Linux: install the `git` package: `sudo apt install git` (ubuntu), `sudo pacman -S git` (arch), etc... (you probably already have it)
3. Install and set up the necessary libraries:
	- `haxelib install lime 7.9.0`
	- `haxelib install openfl 9.2.1`
	- `haxelib install flixel 5.3.1`
	- `haxelib install hxCodec 3.0.2`
	- `haxelib install SScript 6.1.80`
	- `haxelib run lime setup`
	- `haxelib run lime setup flixel`
	- `haxelib install flixel-addons 3.2.0`
	- `haxelib install flixel-ui 2.5.0`
	- `haxelib install tjson`
	- `haxelib gir linc_luajit https://github.com/superpowers04/linc_luajit`
	- `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc`