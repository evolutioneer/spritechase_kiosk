package com.spritechase
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
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
	
	[SWF(width="1024",height="768",fps="60")]
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
		private var idleDelay:int = 30000;
		private var userActive:Boolean = false;
		
		//debug members
		//private var debug_txt:TextField;
		//private var _debugging:Boolean = false;
		//private var testLoader:URLLoader;
		
		/**
		 *********************************************************************/
		public function Kiosk()
		{
			trace('Kiosk()');
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		/**
		 *********************************************************************/
		private function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			//if(_debugging) initDebugger();
			loadKioskConfiguration();
			
		}
		
		/**
		 *********************************************************************/
		/*private function initDebugger():void
		{
			trace('initDebugger()');
			debug_txt = new TextField();
			debug_txt.autoSize = TextFieldAutoSize.LEFT;
			addChild(debug_txt);
			debug_txt.textColor = 0xffffffff;
			debug_txt.background = true;
			debug_txt.backgroundColor = 0x22222222;
		}*/
		
		/**
		 *********************************************************************/
		private function debug(msg:String):void
		{
			trace(msg);
			//if(_debugging) debug_txt.text =  msg + '\n' + debug_txt.text;
		}
		
		/**
		 *********************************************************************/
		private function loadKioskConfiguration():void
		{
			loader = new URLLoader();
			loader.addEventListener("complete", onKioskConfiguration);
			loader.load(new URLRequest('xml/config.xml'));
		}
		
		/**
		 *********************************************************************/
		private function onKioskConfiguration(e:Event):void
		{
			KioskConfig.init(new XML(loader.data));
			loader.removeEventListener("complete", onKioskConfiguration);
			debug('Kiosk.onKioskConfiguration().  KioskConfiguration.data: ' + KioskConfig.data.toXMLString());
			init();
		}
		
		/**
		 *********************************************************************/
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
			
			//Set up the idling logic
			idleTimer = new Timer(idleDelay, 1);
			idleTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIdleTimer);
			
			
			//$$testme does the sharpness filter make any difference?
			//ar.sharpnessFilter = true;
			
			//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ DEBUG
			//$$debug wtf, why am I not getting net connectivity (apparently) in kiosk mode?
			//testLoader = new URLLoader();
			//testLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onDebugHTTPStatus);
			//testLoader.addEventListener(IOErrorEvent.IO_ERROR, onDebugIOError);
			//testLoader.addEventListener(Event.COMPLETE, onDebugLoadComplete);
			//testLoader.load(new URLRequest('http://www.spritechase.com'));
		}
		/*
		private function onDebugIOError(e:IOErrorEvent):void
		{
			debug('onDebugIOError(' + e + ')');
		}
		
		private function onDebugLoadComplete(e:Event):void
		{
			debug('onDebugLoadComplete(' + e + ')');
			debug('++++ data: ' + testLoader.data);
		}
		
		private function onDebugHTTPStatus(e:HTTPStatusEvent):void
		{
			debug('onDebugHTTPStatus(' + e + ')');
		}
		*/
		/**
		 *********************************************************************/
		private function onUILoaded(e:Event):void
		{
			debug('Kiosk.onUILoaded()');
			ui = uiLoader.content as KioskUI;
			
			//Add event listeners
			ui.addEventListener(KioskEvent.NEW_MODEL_SELECTED, onNewModelSelected);
			
			addChild(ui);
			
			//Bbegin in idle mode
			idle();
		}
		
		/**
		 *********************************************************************/
		private function idle():void
		{
			userActive = false;
			lastCode = '';
			candidateCode = '';
			
			unbindActivityEvents();
			ui.idle();
			ar.hideUplinkSpinner();
		}
		
		/**
		 *********************************************************************/
		private function onHandshakeAttempt(e:KioskEvent):void
		{
			if(!userActive)
			{
				idleTimer.start();
				bindActivityEvents();
				ui.onHandshakeAttempt(e);
				ar.showUplinkSpinner();
			}
		}
		
		/**
		 *********************************************************************/
		private function onQrCandidateFound(e:KioskEvent):void
		{
			debug('Kiosk.onQrCandidateFound(' + e.data.code + ')');
			
			if(e.data.code == lastCode || e.data.code == candidateCode)
			{
				debug("... The candidate is the same as the current or pending candidate code");
				return;
			}
			
			var request:URLRequest = new URLRequest(path + e.data.code);
			candidateCode = e.data.code;
			loader.load(request);
		}
		
		/**
		 *********************************************************************/
		private function onServerHTTPStatus(e:HTTPStatusEvent):void
		{
			debug('Kiosk.onServerHTTPStatus(' + e + ')');
		}
		
		/**
		 *********************************************************************/
		private function onServerProgress(e:ProgressEvent):void
		{
			debug('Kiosk.onServerProgress(' + e + ')');
		}
		
		/**
		 *********************************************************************/
		private function onServerIOError(e:IOErrorEvent):void
		{
			debug('Kiosk.onServerIOError(' + e + ')');
		}
		
		/**
		 *********************************************************************/
		private function onServerData(e:Event):void
		{
			debug('Kiosk.onServerData(' + e + ')');
			
			try
			{
				var xml:XML = new XML(loader.data);
				
				//$$debug wtf, why am I seeing an error when there isn't one?
				debug('xml..error: "' + xml..error.toXMLString() + '"');
				
				if(xml..error.toXMLString() != '')
				{
					debug('... Server returned an error: ' + xml..error);
					return;
				}
				
				if(xml..section.(@id == 'user').name == '')
				{
					debug('... Server returned an empty user; ignoring');
					return;
				}
				
				lastData = new KioskData(new XML(loader.data));
			}
			
			catch(e:Error)
			{
				debug('!!! Instancing KioskData failed.  Error: ' + e);
				lastData = null;
			}
			
			if(lastData != null)
			{
				userActive = true;
				
				bindActivityEvents();
				
				idleTimer.stop();
				idleTimer.start();
				
				lastCode = candidateCode;
				ui.init(lastData);
			}
		}
		
		/**
		 *********************************************************************/
		private function onNewModelSelected(e:KioskEvent):void
		{
			debug('Kiosk.onNewModelSelected()');
			ar.update(e.data.id);
		}
		
		/**
		 *********************************************************************/
		private function bindActivityEvents():void
		{
			addEventListener(MouseEvent.MOUSE_MOVE, resetIdleTimer);
			addEventListener(MouseEvent.CLICK, resetIdleTimer);
			ar.addEventListener(KioskEvent.HANDSHAKE_ATTEMPT, resetIdleTimer);
		}
		
		/**
		 *********************************************************************/
		private function unbindActivityEvents():void
		{
			removeEventListener(MouseEvent.MOUSE_MOVE, resetIdleTimer);
			removeEventListener(MouseEvent.CLICK, resetIdleTimer);
			ar.removeEventListener(KioskEvent.HANDSHAKE_ATTEMPT, resetIdleTimer);
		}
		
		/**
		 *********************************************************************/
		private function resetIdleTimer(e:Event = null):void
		{
			if(idleTimer.running)
			{
				idleTimer.stop();
				idleTimer.reset();
				idleTimer.start();
			}
		}
		
		/**
		 *********************************************************************/
		private function onIdleTimer(e:TimerEvent):void
		{
			debug('Kiosk.onIdleTimer()');
			idleTimer.stop();
			idle();
		}
	}
}