import nme.display.*;

import GameProject;
import GOB;


import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.Lib;



typedef GOBJob = { x:Int, y:Int, image:CachedImage };
typedef GOBJobs = Array<GOBJob>;
typedef GOBJobsList = Array<GOBJobs>;


class MapView extends Sprite
{
   public var mWidth : Int;
   public var mHeight : Int;
   public var mTilesX : Float;
   public var mTilesY : Float;
   public var mVisTilesX : Float;
   public var mVisTilesY : Float;

   public var mWindowWidth : Int;
   public var mWindowHeight : Int;


   var mTX:Int;
   var mTY:Int;
   var mMaxGOBHeightOff : Int;
   var mMaxGOBWidthOff : Int;
   public var mScaleX:Float;
   public var mScaleY:Float;

   var mGOBJobsList : GOBJobsList;

   var mMap : GameMap;
   var mOX : Float;
   var mOY : Float;
   
   var mBitmap: Bitmap;
   var mBitmapData : BitmapData;

   public var mGrid : GOBGrid;

   public function new(inWidth:Int, inHeight:Int)
   {
      super();

      mWindowWidth = mWidth = inWidth;
      mWindowHeight = mHeight = inHeight;

      mMaxGOBHeightOff = -96;
      mMaxGOBWidthOff = -96;

      mGOBJobsList = new GOBJobsList();
      for(y in 0...mHeight-mMaxGOBHeightOff)
         mGOBJobsList.push( new GOBJobs() );

      mScaleX = 32.0;
      mScaleY = 32.0;

      mVisTilesX = mTilesX = mWidth/mScaleX;
      mVisTilesY = mTilesY = mHeight/mScaleY;


       mBitmapData = new BitmapData(mWidth,mHeight);
       mBitmap = new flash.display.Bitmap(mBitmapData);
   }

   public function SetWindowSize(inW:Int, inH:Int)
   {
      var scale = Math.min(inW/800, inH/600);
      mBitmap.scaleX = mBitmap.scaleY = scale;
   }

   public function Centre(inCX:Float,inCY:Float) : Void
   {
      if (inCX<mVisTilesX*0.5)
         mOX = 0;
      else if (inCX>mTilesX-mVisTilesX*0.5)
         mOX = mTilesX-mVisTilesX;
      else
         mOX = inCX - mVisTilesX*0.5;

      if (inCY<mVisTilesY*0.5)
         mOY = 0;
      else if (inCY>mTilesY-mVisTilesY*0.5)
         mOY = mTilesY-mVisTilesY;
      else
         mOY = inCY - mVisTilesY*0.5;


   }

   public function Step(inDT:Float) : Void
   {
   }


   public function SetMap(inMap : GameMap,inX : Int, inY:Int) : Void
   {
      mMap = inMap;
      mTilesX = inMap.mWidth;
      mTilesY = inMap.mHeight;
      mOX = inX;
      mOY = inY;

      mGrid = new GOBGrid(0,0,mTilesX,mTilesY, 2, 2);
   }


   public function GetNative() : DisplayObject { return mBitmap; }

   public function BeginRebuild() : Void
   {
      mBitmapData.lock();

      if (mMap==null)
      {
          mBitmapData.fillRect( new Rectangle(0,0,mWidth,mHeight), 0xffff80ff );
      }
      else
      {
          var mx0 = Math.floor(mOX);
          var mx1 = Math.floor(mOX+mWidth/mScaleX+0.999);
          var my0 = Math.floor(mOY);
          var my1 = Math.floor(mOY+mHeight/mScaleY+0.999);

          var layer = mMap.mLayers[0];

          for(my in my0...my1)
          {
             var t0 = my*layer.mWidth;
             for(mx in mx0...mx1)
             {
                var tile = layer.mTiles[t0+mx];
                if (tile!=null)
                   Add(tile,mx,my);
             }
          }
       }
   }

   public function AddDirect(inImage:CachedImage,inX:Int,inY:Int) : Void
   {
      mBitmapData.copyPixels(inImage.mPixels.mData,
                     inImage.mRect, new Point(inX,inY),
                     null,null,true);
   }

   public function Add(inImage:CachedImage,inX:Float,inY:Float) : Void
   {
      var x = Math.round((inX-mOX)*mScaleX) + inImage.mX;
      var y = Math.round((inY-mOY)*mScaleY) + inImage.mY;
      if (x<mWidth && y<mHeight && x>mMaxGOBWidthOff && y>mMaxGOBHeightOff)
         AddDirect(inImage,x,y);
   }


   public function AddYSortGobs(inGOBs:GOBs) : Void
   {
      for(gob in inGOBs)
      {
         if (gob.mCurrent!=null)
         {
            var x = Math.round((gob.mX + gob.mOffsetX - mOX)*mScaleX);
            var y = Math.round((gob.mY + gob.mOffsetY - mOY)*mScaleY);

            x+= gob.mCurrent.mX;
            y+= gob.mCurrent.mY;
            if (x<mWidth && y<mHeight && x>mMaxGOBWidthOff && y>mMaxGOBHeightOff)
            {
               mGOBJobsList[y-mMaxGOBHeightOff].push(
                  { x:x, y:y, image:gob.mCurrent } );
            }
         }
      }

      var job:GOBJob;

      for(jobs in mGOBJobsList)
      {
         while( (job=jobs.pop()) != null)
            AddDirect(job.image,job.x,job.y);
      }
   }



   public function EndRebuild() : Void
   {
       mBitmapData.unlock();
   }

}

