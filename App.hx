import xinf.ony.Application;
import xinf.event.MouseEvent;

import TileTest;


class App extends Application {
    public function new() :Void {
        super();
        
        var container = new TileTest();

        root.attach( container );
        container.resize( root.size.x, root.size.y );
        xinf.erno.Runtime.addEventListener( 
            xinf.event.GeometryEvent.STAGE_SCALED, function(e) {
                container.resize( e.x, e.y );
            });
    }

    public static function main() :Void {
        var app:App = new App();
        app.run();
    }
}
