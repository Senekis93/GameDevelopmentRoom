package  
{
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import playerio.Connection;
	import playerio.DatabaseObject;
	import playerio.Message;
	import playerio.PlayerIOError;
	import ugLabs.net.Kong;
	/**
	 * ...
	 * @author UnknownGuardian
	 */
	public class PlayTimer extends Sprite
	{
		public static var minutesTime:int = 0;
		public var timeDisplay:TimeDisplay;
		
		public static var serverUpdateTime:Timer;
		public static var reconnectTime:Timer;
		
		public function PlayTimer() 
		{
			serverUpdateTime = new Timer(300000, 0);
			//serverUpdateTime = new Timer(10000, 0); //debug purposes
			serverUpdateTime.addEventListener(TimerEvent.TIMER, updateServerTime);
			serverUpdateTime.start();
			
			reconnectTime = new Timer(60000, 0);
			reconnectTime.addEventListener(TimerEvent.TIMER, reconnectCheck);
			reconnectTime.start();
			
			timeDisplay = new TimeDisplay();
			addChild(timeDisplay);
			timeDisplay.texbox.defaultTextFormat = new TextFormat(null, 26, 0x000000, true, null, null, null, null, 'center');
			timeDisplay.texbox.text = getFormattedTime(0);
		}
		

		public function updateServerTime(e:TimerEvent):void
		{
			Main.connection.send("Time");
			//Main.client.bigDB.loadMyPlayerObject(loadedSavedData);
			timeDisplay.texbox.text = getFormattedTime(minutesTime + 5);
		}
		public static function showRepliedTime(m:Message = null, id:String = "", message:String = ""):void
		{
			trace("[PlayTimer][showRepliedTime] m = " + m);
			minutesTime = m.getInt(0);
			Kong.stats.submit("MinutesPlayed", minutesTime);
		}
		
		public function loadedSavedData(o:DatabaseObject):void
		{
			if(o.Time != null)
			{
				var t:int = o.Time;
				t += 5;
				o.Time = t;
				minutesTime = t;
				Kong.stats.submit("MinutesPlayed", t);
				timeDisplay.texbox.text = getFormattedTime(minutesTime);
			}
			else
			{
				o.Time = 5;
				minutesTime = 5;
				timeDisplay.texbox.text = getFormattedTime(minutesTime);
			}
			o.save();
			
		}
		
		public static function reconnectCheck(e:TimerEvent):void
		{
			if (!Main.connection.connected)
			{
				Main.chatDisplay.displayEvent("disconnect","");
				Main.client.multiplayer.createJoinRoom(
					"gdrroom",											//Room id. If set to null a random roomid is used
					"TicTacToe",										//The game type started on the server
					false,												//Should the room be hidden from the lobby?
					{},													//Room data. This data is returned to lobby list. Variabels can be modifed on the server
					{Name:Kong.userName,Type:Main.getHighestUserType(), Color:Main.getTypeColor()},	//User join data
					handleReconnection,											//Function executed on successful joining of the room
					handleReconnectionError										//Function executed if we got a join error
				);
			}
		}
		public static function handleReconnection(connection:Connection):void
		{
			Main.playerList.removeAllPlayers();
			Main.connection = connection;
			Main.connection.addMessageHandler("ChatInit", Main.onInit)
			Main.connection.addMessageHandler("ChatJoin", Main.onJoin);
			Main.connection.addMessageHandler("ChatLeft", Main.onLeave);
			Main.connection.addMessageHandler("ChatMessage", Main.onMessage)
			Main.chatDisplay.displayEvent("reconnect", "");
		}
		public static function handleReconnectionError(error:PlayerIOError):void
		{
			trace("Got", error)
			Main.chatDisplay.displayMessage("...\n[Main][handleReconnectionError][PlayerIOError] " + error + "\n");
			Main.chatDisplay.displayMessage("...\nThis usually can be solved by refreshing the page.");
		}
		public static function stopReconnection():void
		{
			reconnectTime.removeEventListener(TimerEvent.TIMER, reconnectCheck);
			reconnectTime.stop();
		}
		
		
		
		
		public function getFormattedTime(t:int):String
		{
			var min:int = 0;
			var hours:int = 0;
			var days:int = 0;
			var s:String = "";
			while (t > 1440)
			{
				t -= 1440;
				days++;
			}
			while (t > 60)
			{
				t -= 60;
				hours++;
			}
			min = t;
			
			if (days < 10)
			{
				s += "0";
			}
			s += days + ":";
			if (hours < 10)
			{
				s += "0";
			}
			s += hours + ":";
			if (min < 10)
			{
				s += "0";
			}
			s += min;
			
			//for gdr only
			if (days > 99)
			{
				timeDisplay.texbox.defaultTextFormat = new TextFormat(null, 20, 0x000000, true, null, null, null, null, 'center');
			}
			
			return s;
		}
	}

}