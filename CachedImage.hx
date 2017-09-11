import nme.display.Bitmap;
import nme.geom.Rectangle;


class CachedImage
{
   public var mPixels : PixelArray;
   public var mRect : Rectangle;
   public var mX : Int;
   public var mY : Int;

   public function new(inPixels:PixelArray,inX0:Int, inY0:Int)
   {
       mPixels = inPixels;
       mX = inX0;
       mY = inY0;
       mRect = new Rectangle(0,0,inPixels.mWidth,inPixels.mHeight);
   }
}


