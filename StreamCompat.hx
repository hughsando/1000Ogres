import nme.utils.ByteArray;
import nme.utils.Endian;


class StreamCompat
{
   var mImpl : ByteArray;

   public function new(inStream:ByteArray)
   {
      mImpl = inStream;
      mImpl.endian = Endian.LITTLE_ENDIAN;
   }

   inline public function GetHeader() : String
   {
      return mImpl.readUTFBytes(4);
   }

   inline public function GetString() : String
   {
      var n = GetShort();
      return mImpl.readUTFBytes(n);
   }

   inline public function GetInt() : Int
   {
      return mImpl.readInt();
   }

   inline public function GetShort() : Int
   {
      return mImpl.readUnsignedShort();
   }

   inline public function GetByte() : Int
   {
      return mImpl.readUnsignedByte();
   }

}
