/*

  The GOBGrid is used to identify objects within a given region.
  It is used to accelerate collision detection.

  I've decided to use a 1D array of objects lists, rather than a 2D array.
  I have no particular reason for this!

  This contains a fair bit of cut&paste code - the reason for this was
   to test the various iteration options, but in reality, I would only
   use one (maybe two) of these methods.
*/


import GameProject;
import GOB;

typedef GOBsList = Array<GOBs>;

interface GOBVisitor
{
   public function Visit(inOther:GOB) : Bool;
}

class GOBIterator
{
   var mGrid:GOBsList;
   var mGridPos:Int;
   var mGridEnd : Int;
   var mYStep:Int;
   var mWidth:Int;

   var mCurrentList : GOBs;
   var mListPos : Int;
   var mX:Int;

   var mNext : GOB;

   public function new(inGrid:GOBsList,
            inX0:Int,inY0:Int, inX1:Int,inY1:Int, inWidth:Int)
   {
      mGrid = inGrid;
      mWidth = inX1-inX0;
      mYStep = inWidth - mWidth + 1;
      mX = 0;
      mGridPos = inY0*inWidth + inX0;
      mGridEnd = (inY1-1)*inWidth + inX1;
      mCurrentList = mGrid[mGridPos];
      mListPos = 0;
   }

   // Haxe iterator interface
   public function hasNext()
   {
      if (mGridPos >= mGridEnd)
         return false;

      while(true)
      {
         //var n = mWidth + mYStep - 1;
         //trace( "[" + (mGridPos%n) + "," + Math.floor( mGridPos/n ) + "]" );
         if (mListPos<mCurrentList.length)
         {
            mNext = mCurrentList[mListPos++];
            return true;
         }
         mX++;
         if (mX==mWidth)
         {
            mX = 0;
            mGridPos += mYStep;
            if (mGridPos>=mGridEnd)
               return false;
         }
         else
         {
            mGridPos++;
         }
         mCurrentList = mGrid[mGridPos];
         mListPos = 0;
      }
      return false;
   }

   public function next() : GOB
   {
      return mNext;
   }


   // This combines hasNext with next, and returns null when done.
   public function getNext() : GOB
   {
      if (mGridPos >= mGridEnd)
         return null;

      while(true)
      {
         //var n = mWidth + mYStep - 1;
         //trace( "[" + (mGridPos%n) + "," + Math.floor( mGridPos/n ) + "]" );
         if (mListPos<mCurrentList.length)
         {
            return mCurrentList[mListPos++];
         }
         mX++;
         if (mX==mWidth)
         {
            mX = 0;
            mGridPos += mYStep;
            if (mGridPos>=mGridEnd)
               return null;
         }
         else
         {
            mGridPos++;
         }
         mCurrentList = mGrid[mGridPos];
         mListPos = 0;
      }
      return null;
   }


}

typedef GridArea = { x0:Int, y0:Int, x1:Int, y1:Int };

class GOBGrid
{
   public var mGrid:GOBsList;
   public var mCells:Int;
   public var mXCells:Int;
   public var mYCells:Int;

   public var mX0:Float;
   public var mY0:Float;
   public var mXScale:Float;
   public var mYScale:Float;

   public function new(inXMin:Float, inYMin:Float, inXMax:Float, inYMax:Float,
                       inXCellSize:Float, inYCellSize:Float )
   {
      mGrid = new GOBsList();
      mXCells = Math.ceil( (inXMax-inXMin)/inXCellSize + 0.1 );
      mYCells = Math.ceil( (inYMax-inYMin)/inYCellSize + 0.1 );
      mCells = mXCells * mYCells;
      // allocate space.
      var temp = mGrid[mCells-1];
      for(c in 0...mCells)
         mGrid[c] = new Array<GOB>();

      mX0 = inXMin;
      mY0 = inYMin;
      mXScale = 1.0/inXCellSize;
      mYScale = 1.0/inYCellSize;
   }

   public function Move(inObj:GOB) : Void
   {
      var gid = Math.floor( (inObj.mX-mX0)*mXScale) +
                Math.floor( (inObj.mY-mY0)*mYScale) * mXCells;
      var old_gid = inObj.mGID;
      if (gid!=old_gid)
      {
         if (old_gid>0)
         {
            // TODO: efficiency?
            mGrid[old_gid].remove(inObj);
         }
         mGrid[gid].push(inObj);
         inObj.mGID = gid;
      }
   }

   public function Remove(inObj:GOB) : Void
   {
      var old_gid = inObj.mGID;
      if (old_gid>0)
      {
         // TODO: efficiency?
         mGrid[old_gid].remove(inObj);
         inObj.mGID = -1;
      }
   }

   public function GetArea(inX:Float,inY:Float,inRad:Float) : GridArea
   {
      var cx0 = Math.floor((inX-inRad-mX0)*mXScale);
      if (cx0<0) cx0 = 0;
      var cx1 = Math.floor((inX+inRad-mX0)*mXScale) + 1;
      if (cx1>mXCells) cx1 = mXCells;
      var cy0 = Math.floor((inY-inRad-mY0)*mYScale);
      if (cy0<0) cy0 = 0;
      var cy1 = Math.floor((inY+inRad-mY0)*mYScale) + 1;
      if (cy1>mYCells) cy1 = mYCells;

      return {x0:cx0,y0:cy0,x1:cx1,y1:cy1};
   }

   public function VisitClose(inX:Float,inY:Float,inRad:Float,
                     inVisitor: GOBVisitor)
   {
      var cx0 = Math.floor((inX-inRad-mX0)*mXScale);
      if (cx0<0) cx0 = 0;
      var cx1 = Math.floor((inX+inRad-mX0)*mXScale) + 1;
      if (cx1>mXCells) cx1 = mXCells;
      var cy0 = Math.floor((inY-inRad-mY0)*mYScale);
      if (cy0<0) cy0 = 0;
      var cy1 = Math.floor((inY+inRad-mY0)*mYScale) + 1;
      if (cy1>mYCells) cy1 = mYCells;

      for(gy in cy0...cy1)
      {
         var base:Int = gy*mXCells;
         for(gx in cx0...cx1)
         {
            var objs = mGrid[base+gx];
            for(i in 0...objs.length)
            {
               var obj = objs[i];
               if (inVisitor!=obj)
                  if (!inVisitor.Visit(obj))
                     return false;
            }
         }
      }
      return true;
   }

   public function Misses(inX:Float,inY:Float,inRad:Float, inGOB: GOB)
   {
      var cx0 = Math.floor((inX-inRad-mX0)*mXScale);
      if (cx0<0) cx0 = 0;
      var cx1 = Math.floor((inX+inRad-mX0)*mXScale) + 1;
      if (cx1>mXCells) cx1 = mXCells;
      var cy0 = Math.floor((inY-inRad-mY0)*mYScale);
      if (cy0<0) cy0 = 0;
      var cy1 = Math.floor((inY+inRad-mY0)*mYScale) + 1;
      if (cy1>mYCells) cy1 = mYCells;

      for(gy in cy0...cy1)
      {
         var base:Int = gy*mXCells;
         for(gx in cx0...cx1)
         {
            var objs = mGrid[base+gx];
            for(i in 0...objs.length)
            {
               var obj = objs[i];
               if (inGOB!=obj)
               {
                  var dx = inX-obj.mX;
                  var dy = inY-obj.mY;
                  if ( dx*dx+dy*dy < 2)
                     return false;

               }
            }
         }
      }
      return true;
   }



   public function VisitCloseClosure(inX:Float,inY:Float,inRad:Float,
                     inVisitor: GOB -> Bool)
   {
      var cx0 = Math.floor((inX-inRad-mX0)*mXScale);
      if (cx0<0) cx0 = 0;
      var cx1 = Math.floor((inX+inRad-mX0)*mXScale) + 1;
      if (cx1>mXCells) cx1 = mXCells;
      var cy0 = Math.floor((inY-inRad-mY0)*mYScale);
      if (cy0<0) cy0 = 0;
      var cy1 = Math.floor((inY+inRad-mY0)*mYScale) + 1;
      if (cy1>mYCells) cy1 = mYCells;
 
      for(gy in cy0...cy1)
      {
         var base:Int = gy*mXCells;
         for(gx in cx0...cx1)
         {
            var objs = mGrid[base+gx];
            for(i in 0...objs.length)
            {
               if (!inVisitor(objs[i]))
                  return false;
            }
         }
      }
      return true;
   }

   public function GetCloseObjsIterator(inX:Float,inY:Float,inRad:Float)
   {
      var cx0 = Math.floor((inX-inRad-mX0)*mXScale);
      if (cx0<0) cx0 = 0;
      var cx1 = Math.floor((inX+inRad-mX0)*mXScale) + 1;
      if (cx1>mXCells) cx1 = mXCells;
      var cy0 = Math.floor((inY-inRad-mY0)*mYScale);
      if (cy0<0) cy0 = 0;
      var cy1 = Math.floor((inY+inRad-mY0)*mYScale) + 1;
      if (cy1>mYCells) cy1 = mYCells;

      return new GOBIterator(mGrid,cx0,cy0,cx1,cy1,mXCells);
   }

   public function GetCloseObjList(inX:Float,inY:Float,inRad:Float)
   {
      var cx0 = Math.floor((inX-inRad-mX0)*mXScale);
      if (cx0<0) cx0 = 0;
      var cx1 = Math.floor((inX+inRad-mX0)*mXScale) + 1;
      if (cx1>mXCells) cx1 = mXCells;
      var cy0 = Math.floor((inY-inRad-mY0)*mYScale);
      if (cy0<0) cy0 = 0;
      var cy1 = Math.floor((inY+inRad-mY0)*mYScale) + 1;
      if (cy1>mYCells) cy1 = mYCells;

      var result  = new GOBs();
      for(y in cy0...cy1)
      {
         var base = y*mXCells;
         for(x in cx0...cx1)
         {
            var objs = mGrid[base+x];
            for(i in 0...objs.length)
               result.push(objs[i]);
         }
      }
      return result;
   }
}


