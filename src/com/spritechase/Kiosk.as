package com.spritechase
{
	import qtrack.QuadTrackerEvent;
	import flash.display.Loader;
	import flash.events.ProgressEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.utils.Timer;

	import com.spritechase.ar.KioskAR;
	import com.spritechase.ui.KioskUI;
	import com.spritechase.core.*;
	
	[SWF(width="1024",height="768")]
	public class Kiosk extends Sprite
	{
		//Application members
		public var ar:KioskAR;
		public var ui:KioskUI;
		
		//Private members
		private var candidateCode:String;
		private var lastCode:String;
		private var lastData:KioskData;
		private var path:String = 'http://www.spritechase.com/users/kiosk_data/';
		private var loader:URLLoader;
		private var uiLoader:Loader;
		private var idleTimer:Timer;
		private var idleDelay:int = 10000;
		private var userActive:Boolean = false;
		
		public function Kiosk()
		{
			trace('Kiosk()');
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			loadKioskConfiguration();
			//init();
		}
		
		//$$testme load configuration externally
		private function loadKioskConfiguration():void
		{
			loader = new URLLoader();
			loader.addEventListener("complete", onKioskConfiguration);
			loader.load(new URLRequest('xml/config.xml'));
		}
		
		private function onKioskConfiguration(e:Event):void
		{
			KioskConfig.init(new XML(loader.data));
			loader.removeEventListener("complete", onKioskConfiguration);
			trace('Kiosk.onKioskConfiguration().  KioskConfiguration.data: ' + KioskConfig.data.toXMLString());
			init();
		}
		
		private function init():void
		{
			ar = new KioskAR();
			
			//Init the remote data loader
			loader = new URLLoader();
			loader.addEventListener("complete", onServerData);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onServerHTTPStatus);
			loader.addEventListener(ProgressEvent.PROGRESS, onServerProgress);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onServerIOError);
			
			//Prepare the augmented reality app
			addChild(ar);
			ar.addEventListener(KioskEvent.QR_CANDIDATE_FOUND, onQrCandidateFound);
			ar.addEventListener(KioskEvent.HANDSHAKE_ATTEMPT, onHandshakeAttempt);
			ar.addEventListener(qtrack.QuadTrackerEvent.MARKER_MOVE, resetIdleTimer);
			
			//Load up the user interface
			uiLoader = new Loader();
			uiLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onUILoaded);
			uiLoader.load(new URLRequest('KioskUI.swf'));
			
			//$$testme set up the idling logic
			idleTimer = new Timer(idleDelay, 1);
			idleTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIdleTimer);
		}
		
		private function onUILoaded(e:Event):void
		{
			trace('Kiosk.onUILoaded()');
			ui = uiLoader.content as KioskUI;
			
			//$$testme add event listeners
			ui.addEventListener(KioskEvent.NEW_MODEL_SELECTED, onNewModelSelected);
			
			addChild(ui);
			
			//$$debug configure the ui
			//ui.debug = true;
			//ui.idleDelay = 10000;
			
			//$$testme begin in idle mode
			idle();
		}
		
		private function idle():void
		{
			userActive = false;
			lastCode = '';
			candidateCode = '';
			
			removeEventListener(MouseEvent.MOUSE_MOVE, resetIdleTimer);
			ar.removeEventListener(KioskEvent.HANDSHAKE_ATTEMPT, resetIdleTimer);
			ui.idle();
			ar.hideUplinkSpinner();
		}
		
		private function onHandshakeAttempt(e:KioskEvent):void
		{
			if(!userActive)
			{
				idleTimer.start();
				addEventListener(MouseEvent.MOUSE_MOVE, resetIdleTimer);
				ar.addEventListener(KioskEvent.HANDSHAKE_ATTEMPT, resetIdleTimer);
				ui.onHandshakeAttempt(e);
				ar.showUplinkSpinner();
			}
		}
		
		private function onQrCandidateFound(e:KioskEvent):void
		{
			trace('Kiosk.onQrCandidateFound(' + e.data.code + ')');
			
			if(e.data.code == lastCode || e.data.code == candidateCode)
			{
				trace("... The candidate is the same as the current or pending candidate code");
				return;
			}
			
			var request:URLRequest = new URLRequest(path + e.data.code);
			candidateCode = e.data.code;
			loader.load(request);
		}
		
		private function onServerHTTPStatus(e:HTTPStatusEvent):void
		{
			trace('Kiosk.onServerHTTPStatus(' + e + ')');
		}
		
		private function onServerProgress(e:ProgressEvent):void
		{
			trace('Kiosk.onServerProgress(' + e + ')');
		}
		
		private function onServerIOError(e:IOErrorEvent):void
		{
			trace('Kiosk.onServerIOError(' + e + ')');
		}
		
		private function onServerData(e:Event):void
		{
			trace('Kiosk.onServerData(' + e + ')');
			
			
			try
			{
				var xml:XML = new XML(loader.data);
				
				//$$debug wtf, why am I seeing an error when there isn't one?
				trace('xml..error: "' + xml..error.toXMLString() + '"');
				
				if(xml..error.toXMLString() != '')
				{
					trace('... Server returned an error: ' + xml..error);
					return;
				}
				
				if(xml..section.(@id == 'user').name == '')
				{
					trace('... Server returned an empty user; ignoring');
					return;
				}
				
				lastData = new KioskData(new XML(loader.data));
			}
			
			catch(e:Error)
			{
				trace('!!! Instancing KioskData failed.  Error: ' + e);
				lastData = null;
			}
			
			if(lastData != null)
			{
				userActive = true;
				
				addEventListener(MouseEvent.MOUSE_MOVE, resetIdleTimer);
				ar.addEventListener(KioskEvent.HANDSHAKE_ATTEMPT, resetIdleTimer);
				
				idleTimer.stop();
				idleTimer.start();
				
				lastCode = candidateCode;
				ui.init(lastData);
			}
		}
		
		private function onNewModelSelected(e:KioskEvent):void
		{
			trace('Kiosk.onNewModelSelected()');
			ar.update(e.data.id);
		}
		
		private function resetIdleTimer(e:Event = null):void
		{
			if(idleTimer.running)
			{
				idleTimer.stop();
				idleTimer.reset();
				idleTimer.start();
			}
		}
		
		private function onIdleTimer(e:TimerEvent):void
		{
			trace('Kiosk.onIdleTimer()');
			idleTimer.stop();
			idle();
		}
	}
}