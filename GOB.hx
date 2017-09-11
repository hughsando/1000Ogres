/*
  The GOB (Game OBect) calss represents a graphics object that moves
   around the screen. 

  I've been testing its relation to the GOBGrid, and how to iterate over
   other GOBs to detect collisions.
*/

import GameProject;
import CachedImage;
import GOBGrid;
import MapView;


class GOB implements GOBVisitor
{
   var mSheet : AnimationSheet;
   var mDir : Float;
   var mFrame : Float;
   public var mCurrent : CachedImage;
   public var mX : Float;
   public var mY : Float;
   public var mOffsetX : Float;
   public var mOffsetY : Float;
   var mVelX : Float;
   var mVelY : Float;
   var mWidth:Int;
   var mHeight:Int;
   var mMapView: MapView;
   var mGrid : GOBGrid;
   var mRadius : Float;
   var m2Rad : Float;

   var mMoveX:Float;
   var mMoveY:Float;

   // Used by ObjectGrid
   public var mGID : Int;

   public function new(inView:MapView,inSheet:AnimationSheet)
   {
      mMapView = inView;

      mGID = -1;
      mGrid = inView.mGrid;

      mSheet = inSheet;

      mOffsetX = -48/mMapView.mScaleX;
      mOffsetY = -75/mMapView.mScaleY;

      mX = Math.random() * mMapView.mTilesX;
      mY = Math.random() * mMapView.mTilesY;
      mFrame = Math.random();

      mDir = Math.random();
      var v = 0.3 + Math.random();
      mVelX = v*Math.cos(mDir*Math.PI*2.0);
      mVelY = -v*Math.sin(mDir*Math.PI*2.0);

      mCurrent = mSheet.GetFrame(mDir,mFrame);

      mRadius = 1.0;
      // This is how close 2 objects must be to "hit". It assumes all
      //  the objects are the same size.
      m2Rad = 2.0;
   }


   public function Render() : Void
   {
      if (mCurrent!=null)
         mMapView.Add(mCurrent,mX+mOffsetX,mY+mOffsetY);
   }

   public function SetDirFromVel() : Void
   {
      mDir = Math.atan2(-mVelY,mVelX) /(2.0 * Math.PI);
      if (mDir<0) mDir+=1.0;
   }

   function Randomise()
   {
      mDir = Math.random();
      var v = 0.3 + Math.random();
      mVelX = v*Math.cos(mDir*Math.PI*2.0);
      mVelY = -v*Math.sin(mDir*Math.PI*2.0);
  
      mCurrent = mSheet.GetFrame(mDir,mFrame);
   }

   function MissByList()
   {
      var objs = mGrid.GetCloseObjList(mMoveX,mMoveY,m2Rad);
      for(i in 0...objs.length)
      {
         var obj = objs[i];
         if (obj!=this)
         {
            var dx = mMoveX-obj.mX;
            var dy = mMoveY-obj.mY;
            if ( dx*dx+dy*dy < 2)
               return false;
         }
      }
      return true;
   }

   function MissByInlineCode()
   {
      var area = mGrid.GetArea(mMoveX,mMoveY,m2Rad);
      var x0 = area.x0;
      var x1 = area.x1;
      for(gy in area.y0...area.y1)
      {
         var base:Int = gy*mGrid.mXCells;
         for(gx in x0...x1)
         {
            var objs = mGrid.mGrid[base + gx];
            for(i in 0...objs.length)
            {
               var obj = objs[i];
               if (obj!=this)
               {
                  var dx = mMoveX-obj.mX;
                  var dy = mMoveY-obj.mY;
                  if ( dx*dx+dy*dy < 2)
                     return false;
               }
            }
         }
      }
      return true;
   }

   function MissByClosure()
   {
      var self = this;

      return mGrid.VisitCloseClosure( mMoveX, mMoveY, m2Rad,
                 function(inObj:GOB)
                 {
                    var obj:GOB = inObj;
                    if (obj==self) return true;
        
                    var dx = self.mMoveX-obj.mX;
                    var dy = self.mMoveY-obj.mY;
                    return dx*dx+dy*dy >= 2;
                 } );
   }

   function MissByForIterator()
   {
      for(obj in mGrid.GetCloseObjsIterator(mMoveX,mMoveY,m2Rad))
      {
         if (obj!=this)
         {
            var dx = mMoveX-obj.mX;
            var dy = mMoveY-obj.mY;
            if ( dx*dx+dy*dy < 2)
               return false;
         }
      }
      return true;
   }


   function MissByWhileIterator()
   {
      var objs = mGrid.GetCloseObjsIterator(mMoveX,mMoveY,m2Rad);
      var obj = objs.getNext();
      while(obj!=null)
      {
         if (obj!=this)
         {
            var dx = mMoveX-obj.mX;
            var dy = mMoveY-obj.mY;
            if ( dx*dx+dy*dy < 2)
               return false;
         }

         obj = objs.getNext();
      }
      return true;
   }

   // GOBVisitor interface
   public function Visit(inOther:GOB) : Bool
   {
      var obj : GOB = inOther;

      var dx = mMoveX-obj.mX;
      var dy = mMoveY-obj.mY;
      return dx*dx+dy*dy >= 2;
   }



   public function Step(inDT:Float) : Void
   {
      mFrame += inDT;
      mMoveX = mX + inDT * mVelX;
      mMoveY = mY + inDT * mVelY;


      // Try different ways of iterating, and check speed.

      //var miss = MissByList();
      //var miss = MissByInlineCode();
      //var miss =  mGrid.VisitClose( mMoveX, mMoveY, m2Rad, this);
      //var miss =  MissByClosure();
      // var miss =  MissByForIterator();
      //var miss =  MissByWhileIterator();
      var miss =  mGrid.Misses( mMoveX, mMoveY, m2Rad, this);

      if (!miss)
      {
         Randomise();
         return;
      }


      // Ok, we can move ...
      mX = mMoveX;
      mY = mMoveY;

      // Bounce ?
      if (mX>mMapView.mTilesX)
      {
         mX = mMapView.mTilesX;
         mVelX *= -1.0;
         SetDirFromVel();
      }
      if (mY>mMapView.mTilesY)
      {
         mY = mMapView.mTilesY;
         mVelY *= -1.0;
         SetDirFromVel();
      }
      if (mX<0)
      {
         mX =  0;
         mVelX *= -1.0;
         SetDirFromVel();
      }
      // Allow for character height...
      if (mY<2)
      {
         mY =  2;
         mVelY *= -1.0;
         SetDirFromVel();
      }

      mGrid.Move(this);

      mCurrent = mSheet.GetFrame(mDir,mFrame);
   }

   public function MoveTo(inX:Float,inY:Float) : Void
   {
      mX = inX;
      mY = inY;
   }
}

typedef GOBs = Array<GOB>;


