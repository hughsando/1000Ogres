import nme.display.BitmapData;

typedef RGBABlob = nme.display.BitmapData;



class PixelArray
{
   public var mData : RGBABlob;
   public var mWidth : Int;
   public var mHeight : Int;
   var mSize : Int;

   public function new(inWidth:Int, inHeight:Int)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      mSize = mWidth * mHeight;
      mData = new RGBABlob(mWidth,mHeight,true,0xFF00FF00);
   }

   public function PixelCount() : Int { return mWidth*mHeight; }

   public function set(inX:Int, inY:Int, inValue:Int) : Void
   {
         mData.setPixel32(inX,inY,
            (inValue & 0xff00ff00 ) + ((inValue & 0xff0000) >> 16) +
              ((inValue & 0xff)<<16 ) );
   }

   public function SetIndex(inIndex:Int, inValue:Int) : Void
   {
         var y : Int = Math.floor(inIndex / mWidth);
         mData.setPixel32(inIndex - y*mWidth,y,inValue);
   }

}


