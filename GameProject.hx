import PixelArray;
import XMLCompat;
import StreamCompat;
import CachedImage;


typedef TileImageList = Array<CachedImage>;



class Variation
{
   var x:Int;
   var y:Int;
   var name: String;

   public function new(inX : String, inY:String, inName : String)
   {
      x = Std.parseInt(inX);
      y = Std.parseInt(inY);
      name = inName;

      // trace("Set variation: " + x + "," + y + " : " + name);
   }
}

typedef VariationList = Array<Variation>;

class Tile
{
   public var mID : Int;
   public var mVariation : Int;
   public var mWidth: Int;
   public var mHeight: Int;

   public var mX0: Int;
   public var mY0: Int;
   public var mTW: Int;
   public var mTH: Int;

   public var mPixels : PixelArray;

   public function new()
   {
      mID = -1;
   }

   function _FromStream(inStream:StreamCompat, inID : Int) : Void
   {
      mID = inID;
      mWidth = inStream.GetShort();
      mHeight = inStream.GetShort();

      mX0 = inStream.GetShort();
      mY0 = inStream.GetShort();
      mTW = inStream.GetShort();
      mTH = inStream.GetShort();

      mPixels = new PixelArray(mTW,mTH);
      var n = mPixels.PixelCount();



      var pals = inStream.GetByte();
      //trace("Read tile : " + mX0 + "," + mY0 +
      // " : " + mTW + "x" + mTH +"/" + pals);
      if (pals>0)
      {
         var lut = new Array<Int>();
         for(p in 0...pals)
         {
            lut[p] = inStream.GetInt();
         }

         for(y in 0...mTH)
            for(x in 0...mTW)
            {
               var p = inStream.GetByte();
               mPixels.set(x,y,lut[p]);
            }
      }
      else
      {
         for(y in 0...mTH)
            for(x in 0...mTW)
               mPixels.set(x,y,inStream.GetInt());
      }

      if (inStream.GetByte()!=21)
         throw("Invalid end-of-tile.");
   }

   function _FromXML(inTD:XMLCompat) : Void
   {
      mID = Std.parseInt(inTD.get("projid"));
      var palette : Array<Int> = null;

      for( dat in inTD.elements() )
      {
         if (dat.nodeName == "palette")
         {
             palette = new Array<Int>();
             var palette_data : String = dat.firstChild().nodeValue;
             DecodePalette(palette,palette_data);
         }
         else if (dat.nodeName == "data")
         {
            mVariation = Std.parseInt(dat.get("variation"));
            mX0 = 0;
            mY0 = 0;
            mTW = mWidth = Std.parseInt(dat.get("w"));
            mTH = mHeight = Std.parseInt(dat.get("h"));
   
            if (dat.exists("rx")) mX0 = Std.parseInt(dat.get("rx"));
            if (dat.exists("ry")) mY0 = Std.parseInt(dat.get("ry"));
            if (dat.exists("rw")) mTW = Std.parseInt(dat.get("rw"));
            if (dat.exists("rh")) mTH = Std.parseInt(dat.get("rh"));

            var hex_data : String = dat.firstChild().nodeValue;

            DecodeData(hex_data,palette);
         }
         else
            throw("Odd data name:" + dat.nodeName);
      }
   }


   static var _d0: Int;
   static var _d9: Int;
   static var _a: Int;
   static var _f: Int;
   static var _A: Int;
   static var _F : Int;

   function GetHex(inCode:Null<Int>) : Int
   {
      if (inCode==null)
         return -2;
      if (inCode>=_d0 && inCode<=_d9)
         return inCode - _d0;
      if (inCode>=_a && inCode<=_f)
         return inCode - _a + 10;
      if (inCode>=_A && inCode<=_F)
         return inCode - _A + 10;
      return -1;
   }

   function DecodePalette(outPalette:Array<Int>,inHex:String) : Void
   {
      var h:Int;
      var pos:Int = 0;
      while( (h=GetHex( inHex.charCodeAt(pos) )) >= 0)
      {
         var tot:Int = h;
         pos++;

         while( (h=GetHex( inHex.charCodeAt(pos) )) >=0)
         {
            tot = tot*16 + h;
            pos++;
         }
         outPalette.push(tot);

         pos++;
      }
   }


   function DecodeData(inHex:String,inPalette:Array<Int>) : Void
   {
      mPixels = new PixelArray(mTW,mTH);
      var n = mPixels.PixelCount();
      var pos:Int = 0;

      var x: Int = 0;
      var y: Int = 0;

      for(i in 0...n)
      {
         var h:Int;
         while( (h=GetHex( inHex.charCodeAt(pos) )) == -1)
           pos++;
         if (h<0)
            throw("Not enough tile data: " + i + "/" + n);

         var tot:Int = h;
         pos++;

         while( (h=GetHex( inHex.charCodeAt(pos) )) >=0)
         {
            tot = tot*16 + h;
            pos++;
         }

         if (inPalette!=null)
            mPixels.set(x,y,inPalette[tot]);
         else
            mPixels.set(x,y,tot);

         x++;
         if (x>=mTW)
         {
           x = 0;
           y++;
         }

      }
   }

   static public function FromXML(inTD : XMLCompat) : Tile
   {
      var tile = new Tile();
      tile._FromXML(inTD);
      return tile;
   }

   static public function FromStream(inStream : StreamCompat, inID:Int) : Tile
   {
      var tile = new Tile();
      tile._FromStream(inStream,inID);
      return tile;
   }


   static public function DoInit() : Void
   {
      var chars : String = "09afAF";
      _d0 = chars.charCodeAt(0);
      _d9 = chars.charCodeAt(1);
      _a = chars.charCodeAt(2);
      _f = chars.charCodeAt(3);
      _A = chars.charCodeAt(4);
      _F = chars.charCodeAt(5);
   }

}

typedef TileList = Array<Tile>;

typedef TileIDs = Array<Int>;

class Layer
{
   public var mWidth:Int;
   public var mHeight:Int;
   public var mName:String;
   public var mType:Int;
   public var mTiles : TileImageList;

   public function new()
   {
      mTiles = new TileImageList();
   }

   function _FromXML(inLUT:TileImageList,inXML : XMLCompat,inWidth:Int,inHeight : Int) : Void
   {
      mName = inXML.get("name");
      mWidth = inWidth;
      mHeight = inHeight;
      mType = Std.parseInt(inXML.get("type"));


      for(block in inXML.elements())
      {
         if (block.nodeName=="vals")
         {
            var vals : Array<String> = block.firstChild().nodeValue.split(",");
            for(val in vals)
            {
               mTiles.push( inLUT[ Std.parseInt(val) ] );
            }
         }
      }
 
      if (mTiles.length != mWidth*mHeight)
         throw("Bad tile count" + mTiles.length + "/" + mWidth*mHeight );
   }

   function _FromStream(inLUT:TileImageList,inStream : StreamCompat,
                  inWidth:Int,inHeight : Int) : Void
   {
      mName = inStream.GetString();
      mType = inStream.GetShort();
      inStream.GetByte();

      mWidth = inWidth;
      mHeight = inHeight;

      for(block in 0...mWidth*mHeight)
      {
         var bid = inStream.GetShort();
         var rot = inStream.GetShort();
         mTiles.push( inLUT[bid] );
      }
   }


   static public function FromXML(inLUT:TileImageList,
                     inXML:XMLCompat,inWidth:Int,inHeight:Int) : Layer
   {
      var layer :Layer = new Layer();

      layer._FromXML(inLUT,inXML,inWidth,inHeight);

      return layer;
   }
   static public function FromStream(inLUT:TileImageList,
                     inStream:StreamCompat,inWidth:Int,inHeight:Int) : Layer
   {
      var layer :Layer = new Layer();

      layer._FromStream(inLUT,inStream,inWidth,inHeight);

      return layer;
   }

}

typedef LayerList = Array<Layer>;

class GameMap
{
   public var mName : String;
   public var mType : Int;
   public var mWidth : Int;
   public var mHeight : Int;
   public var mLayers : LayerList;

   public function new()
   {
      mLayers = new LayerList();
   }

   function _FromXML(inLUT:TileImageList,inXML : XMLCompat) : Void
   {
      mName = inXML.get("name");
      mWidth = Std.parseInt(inXML.get("x"));
      mHeight = Std.parseInt(inXML.get("y"));
      mType = Std.parseInt(inXML.get("type"));

      for( child in inXML.elements() )
      {
         if (child.nodeName == "layers")
         {
             for( l in child.elements() )
             {
                var layer : Layer = Layer.FromXML(inLUT,l,mWidth,mHeight);
                if (layer!=null)
                   mLayers.push(layer);
             }
         }
         else
         {
            // trace("Ignore:" + child.nodeName);
         }
      }
   }

   function _FromStream(inTiles:TileImageList,inStream:StreamCompat)
   {
      mName = inStream.GetString();
      mType = inStream.GetShort();
      mWidth = inStream.GetShort();
      mHeight = inStream.GetShort();
      //trace("GameMap :" + mName + "  "+ mWidth + "x" + mHeight );
      var layers = inStream.GetShort();

      for(l in 0...layers)
         mLayers.push( Layer.FromStream(inTiles,inStream,mWidth,mHeight) );
   }

   static public function FromStream(inLUT:TileImageList,inStream:StreamCompat) : GameMap
   {
      var result : GameMap = new GameMap();
      result._FromStream(inLUT,inStream);
      return result;
   }

   static public function FromXML(inLUT:TileImageList,inXML : XMLCompat) : GameMap
   {
      var result : GameMap = new GameMap();
      result._FromXML(inLUT,inXML);
      return result;
   }

}

typedef MapList = haxe.ds.StringMap<GameMap>;

typedef AnimationFrames = Array<CachedImage>;

class AnimationSheet
{
   var mRow0 : Int;
   var mRowN : Int;

   var mRowLen : Array<Int>;
   var mRowStart : Array<Int>;

   var mFrames : AnimationFrames;

   public function new(inMap : GameMap,inTiles : TileImageList)
   {
      mFrames = new AnimationFrames();
      mRowLen = new Array<Int>();
      mRowStart = new Array<Int>();
      mRow0 = 0;
      mRowN = inMap.mHeight;

      var tiles = inMap.mLayers[0].mTiles;

      var frame_id : Int = 0;

      // trace("Animtion " + inMap.mName );

      for(y in 0...mRowN)
      {
         var start : Int = (y+mRow0) * inMap.mWidth;
         mRowStart.push(frame_id);

         var x :Int = 0;
         while(x<inMap.mWidth)
         {
            var tile = tiles[start+x];
            if (tile==null)
               break;

            mFrames.push(tile);

            frame_id++;
            x++;
         }

         mRowLen.push(x);
      }

   }

   public function GetFrame(inDirection:Float, inFraction:Float) : CachedImage
   {
      if (inDirection<0)
         inDirection -= Math.floor(inDirection + (1.0/16.0) );
      var row : Int = Math.floor( inDirection * mRowN ) % mRowN;

      if (inFraction<0)
         inFraction += Math.floor(inFraction);

      var l = mRowLen[row];
      return mFrames[ (Math.floor(inFraction*l) % l) + mRowStart[row] ];
   }
}

class GameProject
{
   public var mVariations : VariationList;
   public var mTiles : TileImageList;
   public var mMaps : MapList;
   var mFilename : String;

   public function new(inFilename:String)
   {
      Tile.DoInit();

      mVariations = new VariationList();
      mTiles = new TileImageList();
      mMaps = new MapList();
      mFilename =  inFilename;
   }

   public function Load(cb:Void->Void) : Void
   {
      var data = nme.Assets.getBytes(mFilename);
      data.uncompress();
      ReadStream( new StreamCompat(data) );
      cb();
   }

   function ReadStream(inStream:StreamCompat) : Void
   {
      var name = inStream.GetHeader();
      if (name!="GM2D")
         throw("Not a GM2D file.");

      var tiles = inStream.GetInt() + 1;
      for(t in 1...tiles)
      {
         var tile = Tile.FromStream(inStream,t);
         mTiles[tile.mID] = new CachedImage(tile.mPixels,tile.mX0,tile.mY0);
      }

      var maps = inStream.GetInt();
      for(m in 0...maps)
      {
         var map = GameMap.FromStream(mTiles,inStream);
         mMaps.set(map.mName,map);
      }
   }


   function ReadXML(inProject:XMLCompat) : Void
   {
       for( child in inProject.elements() )
       {
          switch(child.nodeName)
          {
             // case "variations" : ReadVariations(child);
             case "tiles" : ReadTiles(child);
             case "maps" : ReadMaps(child);
             default: trace("Unknown type:" + child.nodeName);
          }
       }
   }

   function ReadVariations(inList:XMLCompat) : Void
   {
       for( v in inList.elements() )
       {
          mVariations.push(
           new Variation( v.get("x"), v.get("y"), v.firstChild().nodeValue ) );
       }
   }

   function ReadTiles(inList:XMLCompat) : Void
   {
       for( child in inList.elements() )
       {
          if (child.nodeName == "tile")
          {
             var tile = Tile.FromXML(child);
             mTiles[tile.mID] = new CachedImage(tile.mPixels,tile.mX0,tile.mY0);
          }
       }
   }

   public function CreateAnimationSheet(inName : String) : AnimationSheet
   {
      if (!mMaps.exists(inName))
         throw("Could not find animation : " + inName);

      return new AnimationSheet(mMaps.get(inName),mTiles);
   }

   public function GetMap(inName : String) : GameMap
   {
      if (!mMaps.exists(inName))
         throw("Could not find map : " + inName);

      return mMaps.get(inName);
   }

   function ReadMaps(inList:XMLCompat) : Void
   {
      for( m in inList.elements() )
      {
         //trace("map " + m.get("name") );
         var map =  GameMap.FromXML(mTiles,m);
         mMaps.set(map.mName,map);
      }
   }

}

