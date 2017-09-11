/*

  The hx XML node it too slow in flash.  This allows us to use the
  
  same code in neko and flash.
*/

#if flash9

import flash.xml.XMLDocument;
import flash.xml.XMLNode;
typedef XMLN = XMLNode;

#else

typedef XMLN = Xml;

#end



class XMLCompat
{
   var mNode : XMLN;

   public function new(inNode : XMLN) { mNode = inNode; }

   public static function CreateFromString(inString:String) : XMLCompat
   {
      #if flash9
      var doc : XMLDocument = new XMLDocument();
      doc.parseXML(inString);

      return  new XMLCompat(doc).firstElement();
      #else

      return new XMLCompat( Xml.parse(inString).firstElement() );

      #end
   }

   public function elements() : Array<XMLCompat>
   {
     var elems = new Array<XMLCompat>();
     #if flash9
     for( child in mNode.childNodes)
     {
        if (child.nodeType ==flash.xml.XMLNodeType.ELEMENT_NODE)
           elems.push(new XMLCompat(child));
     }
     #else
     for( child in mNode.elements())
        { elems.push(new XMLCompat(child)); }
     #end
     return elems;
   }

   public var nodeName(get_nodeName,null) : String;
   function get_nodeName() : String { return mNode.nodeName; }

   public var nodeValue(get_nodeValue,null) : String;
   function get_nodeValue() : String { return mNode.nodeValue; }



#if flash9
        public function get(inName:String) : String
           {
              return Reflect.field(mNode.attributes,inName);
           }

        public function firstChild() : XMLCompat
           { return new XMLCompat(mNode.firstChild); }

        public function exists(inName:String) : Bool
           {   return Reflect.hasField(mNode.attributes,inName); }

        public function firstElement() : XMLCompat
        {
           for( child in mNode.childNodes)
           {
              if (child.nodeType ==flash.xml.XMLNodeType.ELEMENT_NODE)
                 return new XMLCompat(child);
           }
           return null;
        }
#else

   public function get(inName:String) : String
     { return mNode.get(inName); }

   public function firstChild() : XMLCompat
     { return new XMLCompat( mNode.firstChild() ); }

   public function firstElement() : XMLCompat
     { return new XMLCompat(mNode.firstElement()); }

   public function exists(inName:String) : Bool
     { return mNode.exists(inName); }

#end

}


