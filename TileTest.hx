import nme.display.*;
import nme.text.*;
import nme.events.*;

import GameProject;
import GOB;
import GOBGrid;


class Ogre extends GOB
{
   var mHero : GOB;

   public function new(inView:MapView,inSheet:AnimationSheet,inHero:GOB)
   {
      super(inView,inSheet);
      mHero = inHero;
   }

   public override function Step(inDT:Float) : Void
   {
      var dx = mX - mHero.mX;
      var dy = mY - mHero.mY;
      var dist2 = dx*dx+dy*dy;
      if (dist2<25 && dist2>0)
      {
         var len = Math.sqrt(dist2);
         var weight = 5-len;
         mVelX += weight*inDT*dx/len;
         mVelY += weight*inDT*dy/len;
         var v2 = mVelX*mVelX + mVelY*mVelY;
         if (v2>2.0)
         {
            var s = Math.sqrt(2.0/v2);
            mVelX *= s;
            mVelY *= s;
         }
         SetDirFromVel();
      }
      super.Step(inDT);
   }
}

typedef Ogres = Array<Ogre>;



class TileTest extends Sprite
{
    var mProj : GameProject;
    var mMapView : MapView;
    var mTileImages : TileImageList;

    var mHero : GOB;
    var mOgre : Ogres;
    var mAllGobs : GOBs;

    var mWindowWidth : Int;
    var mWindowHeight : Int;

    var mMoveTime : Float;

    var mOgreSheet : AnimationSheet;

    public var fps_disp:TextField;

    public function new() :Void
    {
       mWindowWidth = 800;
       mWindowHeight = 600;
       mMoveTime = 0;

       super();

       mMapView = new MapView(800,600);
       addChild(mMapView.GetNative());


       fps_disp = new TextField();
       fps_disp.selectable = false;
       fps_disp.x=10;
       fps_disp.y=10;
       fps_disp.width = 400;
       fps_disp.border = false;
       fps_disp.borderColor = 0xCCCCCC;
       addChild(fps_disp);
       fps_disp.text = 'Loading...';

       stage.addEventListener(Event.RESIZE, Resize );
       stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown );

       mProj = new GameProject("GameData.gmz");
       mProj.Load(OnComplete);
   }


    function Resize( e:Dynamic ) :Void
    {
       mWindowWidth = e.x;
       mWindowHeight = e.y;
       mMapView.SetWindowSize(mWindowWidth,mWindowHeight);
    }

    function OnKeyDown( e:KeyboardEvent ) :Void
    {
       var code  = e.keyCode;
       // Space
       if (code==32)
       {
          AddOgres(100);
          mMoveTime = 0;
       }
    }




    function AddOgres(inN:Int)
    {
       for(i in 0...inN)
       {
          var o = new Ogre(mMapView,mOgreSheet,mHero);
          mOgre.push(o);
          mAllGobs.push(o);
       }
    }

    function OnComplete() : Void
    {
        fps_disp.text = 'Loaded.';
        var run = mProj.CreateAnimationSheet("Archer - Run");
        mOgreSheet = mProj.CreateAnimationSheet("Ogre - Run");

        mMapView.SetMap( mProj.GetMap("World"), 0, 0);

        mAllGobs = new GOBs();

        mHero = new GOB(mMapView,run);
        mHero.MoveTo(10,10);

        mOgre = new Ogres();

        AddOgres(1000);
        mAllGobs.push(mHero);

        stage.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
        stage.addEventListener( Event.ENTER_FRAME, onFrame );
    }

    function onMouseDown( e:MouseEvent ) :Void
    {
    }

    function onFrame( _ ) :Void
    {
       var time1:Float = haxe.Timer.stamp();

       mMapView.Step(0.1);
       for(gob in mAllGobs)
          gob.Step(0.1);

       mMoveTime += (haxe.Timer.stamp() - time1 - mMoveTime) * 0.01;

       mMapView.Centre(mHero.mX,mHero.mY);

       mMapView.BeginRebuild();

       mMapView.AddYSortGobs(mAllGobs);
       mMapView.EndRebuild();

       fps_disp.text = (Std.int(mMoveTime*100000)*0.01) + " ms";
    }
}

