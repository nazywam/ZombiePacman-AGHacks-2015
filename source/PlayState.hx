package;

import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import openfl.Assets;
import openfl.utils.ByteArray;

import sys.net.Host;
import sys.net.Socket;

class PlayState extends FlxState
{

	var actors : Array<Actor>;
	var grid : Array<Array<Tile>>;
	var collectibles : Array<Array<Collectible>>;

	var socket : Socket;
	var clientId : Int;
	var playersNumber : Int;

	public static var ONLINE : Bool = true;

	override public function create():Void
	{
		super.create();
		//FlxG.log.redirectTraces = true;
		FlxG.autoPause = false;

		actors = new Array<Actor>();

		if(ONLINE){

			socket = new Socket();
			socket.setTimeout(1);
			try {
				socket.connect(new Host("10.10.97.146"), 8888);
			} 
			catch(e:Dynamic){
				trace("Couldn't connect to server");
			}
			socket.output.writeString("READY");
			socket.output.flush();

			while(true){
				var players = getLine();
				if(players == "START"){
					break;
				} else if (players != ""){
					trace(players, " player ready");
				}
			}
			var tmp = getLine().split(":");

			clientId = Std.parseInt(tmp[0]);
			trace("Client Id: ", clientId);

			var selectedMap:Int = Std.parseInt(tmp[1]);
			loadMap("assets/data/level" + selectedMap + ".txt");
			trace("Map: ", selectedMap);

			var playerPos = getLine().split(":");
			for(i in 0...playerPos.length){
				var xy = playerPos[i].split("x");
				trace(xy);
				var a = new Actor(Std.parseInt(xy[0]), Std.parseInt(xy[1]));
				actors.push(a);
				add(a);
			} 
		} else {
			clientId = 0;
			var a = new Actor(1, 1);
			actors.push(a);
			add(a);
			loadMap("assets/data/level"+Std.string(Std.random(10))+".txt");
		}
		trace("tick");
		tick();
	}

	function getLine(){
		for(y in 0...123456789){
			var a = "";

			try {
				var tmp = socket.input.readLine();
				trace(tmp);
				return  tmp;
			}
			catch (e:Dynamic){
			}
		}
		return "";
	}

	public function loadMap(mapPath:String){
		var _map = Assets.getText(mapPath);
		var _lines =_map.split('\n');

		collectibles = new Array<Array<Collectible>>();
		grid = new Array<Array<Tile>>();

		for(l in 0..._lines.length){
			grid[l] = new Array<Tile>();
			collectibles[l] = new Array<Collectible>();

			var _rows = _lines[l].split(',');
			for(r in 0..._rows.length){
				var t = new Tile(r, l, Std.parseInt(_rows[r])-1);
				add(t);
				grid[l].push(t);

				collectibles.push(null);

				if(Std.parseInt(_rows[r]) == 1){
					var c = new Collectible(r, l);
					add(c);
					collectibles[l][r] = c;
				}
			}
		}
	}
	
	function getTile(_y:Float, _x:Float){
		return grid[Std.int(_y)][Std.int(_x)];
	}

	public function preTick(){
		if(ONLINE){
			socket.output.writeString(Std.string(actors[clientId].pressedDirection));
			socket.output.flush();

			var d = getLine();
			var directions = d.split("_");
			for(i in 0...directions.length){
				actors[i].pressedDirection = Std.parseInt(directions[i]);
			}
		}

		tick();
	}

	function validMove(a:Actor, d:Int){
		switch (d) {
			case FlxObject.UP:
				if(getTile(a.gridPos.y-1, a.gridPos.x).tileId !=  0){
					return false;
				}
			case FlxObject.RIGHT:
				if(getTile(a.gridPos.y, a.gridPos.x+1).tileId !=  0){
					return false;
				}
			case FlxObject.DOWN:
				if(getTile(a.gridPos.y+1, a.gridPos.x).tileId !=  0){
					return false;
				}
			case FlxObject.LEFT:
				if(getTile(a.gridPos.y, a.gridPos.x-1).tileId !=  0){
					return false;
				}
		}

		return true;
	}

	public function tick(){
		for(a in actors){
			if(!validMove(a, a.pressedDirection)){
				if(validMove(a, a.previousPressedDirection)){
					a.pressedDirection = a.previousPressedDirection;
				} else {
					a.canMove = false;
				}
			}
			a.tick();

			var gridY = Std.int(a.gridPos.y);
			var gridX = Std.int(a.gridPos.x);

			if(collectibles[gridY][gridX] != null && !collectibles[gridY][gridX].taken){
				collectibles[gridY][gridX].taken = true;
				collectibles[gridY][gridX].visible = false;
				//FlxG.camera.color = 0xFF000000 + Std.random(0xFFFFFF);
				
			}
		}


		var t = new FlxTimer();
		t.start(Settings.TICK_TIME, function(_){
			preTick();
		});
	}

	function handleKeys(){
		if(FlxG.keys.justPressed.UP){
			actors[clientId].pressedDirection = FlxObject.UP;
		}
		if(FlxG.keys.justPressed.RIGHT){
			actors[clientId].pressedDirection = FlxObject.RIGHT;	
		}

		if(FlxG.keys.justPressed.DOWN){
			actors[clientId].pressedDirection = FlxObject.DOWN;
		}

		if(FlxG.keys.justPressed.LEFT){
			actors[clientId].pressedDirection = FlxObject.LEFT;
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		handleKeys();
	}	
}