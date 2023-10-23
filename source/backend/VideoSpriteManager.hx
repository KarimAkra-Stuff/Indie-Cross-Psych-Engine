#if VIDEOS_ALLOWED
package backend;
#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideoSprite as VideoSprite;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoSprite;
#elseif (hxCodec == "2.6.0") import VideoSprite;
#else import vlc.MP4Sprite as VideoSprite; #end
#end
import states.PlayState;

/*A class made to handle VideoSprites from diffrent hxCodec versions*/
class VideoSpriteManager extends VideoSprite {
   // @:isVar
    var onPlayState(null, set):Bool;

    public function new(x:Float = 0, y:Float = 0 #if (hxCodec < "2.6.0"),width:Float = 1280, height:Float = 720, autoScale:Bool = true #end){
        super(x, y #if (hxCodec < "2.6.0"),width, height, autoScale #end);
       if(onPlayState)
            PlayState.instance.videoSprites.push(this); //hopefully will put the VideoSprite var in the array
        trace('playstate status: $onPlayState');
    }
    #if VIDEOS_ALLOWED
    
    /**
        * Native video support for Flixel & OpenFL
        * @param Path Example: `your/video/here.mp4`
        * @param Loop Loop the video.
        */
        public function startVideo(path:String, loop:Bool = false) {
            #if (hxCodec >= "3.0.0")
            this.play(path, loop);
            #else
            this.playVideo(path, loop, false);
            #end
           if(onPlayState)
                setPlayBackRate(PlayState.instance.playbackRate);
    }

    	/**
	 * Adds a function that is called when the Video ends.
	 * @param func Example: `function() { //code to run }`
	*/
    public function setFinishCallBack(func:Dynamic){
        #if (hxCodec >= "3.0.0")
        this.bitmap.onEndReached.add(function() {
            //this.bitmap.dispose(); //i'm not sure about this...
            if(func != null)
                func();
        }, true);
        #else
        if(func != null)
        this.bitmap.finishCallback = func;
        #end
    }

    	 /**
	 * Adds a function which is called when the Codec is opend(video starts).
	 * @param func Example: `function() { //code to run }`
	 */
    public function setStartCallBack(func:Dynamic){
        #if (hxCodec >= "3.0.0")
        if(func != null)
        this.bitmap.onOpening.add(func, true);
        #else
        if(func != null)
        this.bitmap.openingCallback = func;
        #end
    }
    public function forcePause()
        {
        #if (hxCodec >= "3.0.0")
        super.pause();
        if (FlxG.autoPause)
            {
                if (FlxG.signals.focusGained.has(this.resume))
                    FlxG.signals.focusGained.remove(this.resume);
    
                if (FlxG.signals.focusLost.has(this.pause))
                    FlxG.signals.focusLost.remove(this.pause);
            }
        #else
        this.bitmap.pause();
        if (FlxG.autoPause)
            {
                if (FlxG.signals.focusGained.has(this.bitmap.resume))
                    FlxG.signals.focusGained.remove(this.bitmap.resume);
    
                if (FlxG.signals.focusLost.has(this.bitmap.pause))
                    FlxG.signals.focusLost.remove(this.bitmap.pause);
            }
        #end
    }

    public function forceResume()
        {
       #if (hxCodec >= "3.0.0")
        super.resume();
        if (FlxG.autoPause)
            {
                FlxG.signals.focusGained.add(this.resume);
                FlxG.signals.focusLost.add(this.pause);
            }
        #else
        this.bitmap.resume();
        if (FlxG.autoPause)
            {
                FlxG.signals.focusGained.add(this.bitmap.resume);
                FlxG.signals.focusLost.add(this.bitmap.pause);
            }
        #end
    }

    //REAL
    public function setPlayBackRate(multi:Float){
        this.bitmap.rate = multi;
    }
    #end

    inline private function set_onPlayState(value:Bool):Bool
        {
            onPlayState = (Std.isOfType(MusicBeatState.getState(), states.PlayState));
            return onPlayState;
        }
}
#end
