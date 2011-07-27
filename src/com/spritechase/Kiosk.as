package com.spritechase
{
	import flash.display.Loader;
	import flash.events.ProgressEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.Sprite;	

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
		private var lastCode:String;
		private var path:String = 'http://www.spritechase.com/users/kiosk_data/';
		private var loader:URLLoader;
		private var uiLoader:Loader;
		
		public function Kiosk()
		{
			trace('Kiosk()');
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			init();
		}
		
		private function init():void
		{
			ar = new KioskAR();
			
			//Init the remote data loader
			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onServerData);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onServerHTTPStatus);
			loader.addEventListener(ProgressEvent.PROGRESS, onServerProgress);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onServerIOError);
			
			//Prepare the augmented reality app
			addChild(ar);
			ar.addEventListener(KioskEvent.QR_CANDIDATE_FOUND, onQrCandidateFound);
			
			//Load up the user interface
			uiLoader = new Loader();
			uiLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onUILoaded);
			uiLoader.load(new URLRequest('KioskUI.swf'));
		}
		
		private function onUILoaded(e:Event):void
		{
			trace('onUILoaded()');
			ui = uiLoader.content as KioskUI;
			addChild(ui);
		}
		
		private function onCleanQRFound(e:KioskEvent):void
		{
			trace('++++ onCleaNQRFound(' + e.data.code + ')');
		}
		
		private function onQrCandidateFound(e:KioskEvent):void
		{
			trace('++++ onQrCandidateFound(' + e.data.code + ')');
			//$$todo attempt a net connection with this QR code
			
			var request:URLRequest = new URLRequest(path + e.data.code);
			loader.load(request);
		}
		
		private function onServerHTTPStatus(e:HTTPStatusEvent):void
		{
			trace('onServerHTTPStatus(' + e + ')');
		}
		
		private function onServerProgress(e:ProgressEvent):void
		{
			trace('onServerProgress(' + e + ')');
		}
		
		private function onServerIOError(e:IOErrorEvent):void
		{
			trace('onServerIOError(' + e + ')');
		}
		
		private function onServerData(e:Event):void
		{
			trace('onServerData(' + e + ')');
		}
	}
}