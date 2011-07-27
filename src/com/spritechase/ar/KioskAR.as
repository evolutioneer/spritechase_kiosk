package com.spritechase.ar

{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import away3d.loaders.parsers.OBJParser;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextField;
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import com.logosware.event.QRdecoderEvent;
	import com.logosware.event.QRreaderEvent;
	import com.logosware.utils.QRcode.QRdecode;
	import com.logosware.utils.QRcode.GetQRimage;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;

	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.View3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.loaders.Loader3D;

	import qtrack.QuadTracker;
	import qtrack.QuadMarker;
	import qtrack.QuadTrackerEvent;
	
	import com.spritechase.core.*;

	/**
	 * @author Ross
	 */
	[SWF (width=640, height=640, backgroundColor=0)]
	public class KioskAR extends Sprite {
		
		//QTracker properties
		[Embed (source='../bin/assets/compudog.gif')]
		private var MarkerImage:Class;
		private var tracker:QuadTracker;
		
		//Away3d properties
		private var view:View3D;
		private var container:ObjectContainer3D;
		private var model:Loader3D;
		private var video:VideoPlane;
		private var focalLength:Number;
		
		//QR reader and homology properties
		//[Embed(source="../bin/assets/homography_test.png")]
		//private var SourceImage:Class;
		private var homography:Homography;
		private var qrReaderHomography:GetQRimage;
		private var qrDecoder:QRdecode;
		private var qrSample:BitmapData;
		private var qrMessageCt:uint = 0;
		private var qrMessages:Vector.<String> = new Vector.<String>(32, true);
		private var qrMessageThreshold:int = 5;
		private var corners:Vector.<Point> = new Vector.<Point>(4, true);
		private var rawPoseData:Vector.<Number> = new Vector.<Number> (16);
		
		private var debugTrace:TextField;
		
		//Application state
		private var _debugging:Boolean = true;
		
		//Remove model timer
		private var removeModelTimer:Timer;
		
		/**
		 *********************************************************************/
		public function KioskAR()
		{
			trace('KioskAR()');
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/**
		 *********************************************************************/
		private function init(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			//$$debug add the text trace to the stage
			/*debugTrace = new TextField();
			addChild(debugTrace);
			
			debugTrace.textColor = 0xffffff;
			debugTrace.autoSize = TextFieldAutoSize.LEFT;
			debugTrace.backgroundColor = 0x33000000;
			debugTrace.background = true;
			debugTrace.alpha = 0.5;
			
			debugTrace.height = stage.stageHeight;
			debugTrace.width = 200;*/
			
			//Initialize the removeTimer
			removeModelTimer = new Timer(1000, 0);
			removeModelTimer.addEventListener(TimerEvent.TIMER, onRemoveModelTimer);
			
			//Initialize away3d scene graph
			view = new View3D();
			addChild(view);
			//Loader3D.enableParser(Max3DSParser);
			//$$testme let's load and parse an OBJ of our own making, shall we!??!
			Loader3D.enableParser(OBJParser);
			model = new Loader3D();
			model.load(new URLRequest('assets/test.obj'));
			model.rotationX = -90;
			//model.scale(0.1);
			
			container = new ObjectContainer3D();
			container.addChild(model);
			
			//Initialize away3d camera
			view.camera.z = 0;
			view.camera.lens = new PerspectiveLens(50);
			
			focalLength = view.height / Math.tan (
				PerspectiveLens (view.camera.lens).fieldOfView * Math.PI / 180
			);
			
			//Initialize qtracker
			tracker = new QuadTracker(
				new QuadMarker(new MarkerImage()),
				0, 640, 480, focalLength
			);
			
			tracker.confidenceThreshold = 0.4;
			tracker.mirrored = false;
			
			tracker.addEventListener(QuadTrackerEvent.MARKER_FOUND, onMarkerFound);
			tracker.addEventListener(QuadTrackerEvent.MARKER_LOST, onMarkerLost);
			tracker.addEventListener(QuadTrackerEvent.MARKER_MOVE, onMarkerMove);
			
			video = new VideoPlane(tracker, view.camera.lens.far * 0.95);
			view.scene.addChild(video);
			video.material.bothSides = true;
			video.transform.prependRotation(180, new Vector3D(0, 1, 0));
			
			//_debug let's make sure all things are good in qtracker hood
			//addChild(tracker.getDebugOverlay());
			
			//Initialize qr reader and homography
			homography = new Homography();
			addChild(homography);
			//Deferred the creation of the QR properties until homography has valid bitmap data
			
			//Fire the guns
			tracker.start();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		/**
		 *********************************************************************/
		private function searchForQR():void
		{
			if(qrMessageCt >= qrMessages.length) return;
			
			if(!qrDecoder)
			{
				qrDecoder = new QRdecode();
				qrDecoder.addEventListener(QRdecoderEvent.QR_DECODE_COMPLETE, onQrDecodeComplete);
			
			}
			
			if(!qrSample) qrSample = new BitmapData(tracker.videoWidth, tracker.videoHeight);
			qrSample.draw(tracker);
			
			drawHomography();
			
			if(!qrReaderHomography)
			{
				qrReaderHomography = new GetQRimage(homography);
				qrReaderHomography.addEventListener(QRreaderEvent.QR_IMAGE_READ_COMPLETE, onQrImageRead);
			}
			
			qrReaderHomography.process();
		}
		
		/**
		 *********************************************************************/
		private function drawHomography():void
		{
			if(!corners) corners = new Vector.<Point>(4, true);
			var i:int = 0;
			
			//correct for the center-origin plane space thing
			for(i = 0; i < tracker.markerCorners.length; i++)
			{
				corners[i] = new Point(
					tracker.markerCorners[i].x + (tracker.videoWidth / 2),
					tracker.markerCorners[i].y + (tracker.videoHeight / 2)
				);
			}
			
			var scaleX:Number = 0.8;
			var scaleY:Number = 0.8;
			var newCorners:Vector.<Point> = new Vector.<Point>(4, true);
			
			newCorners[0] = new Point(corners[0].x * scaleX + corners[1].x * (1 - scaleX), corners[0].y * scaleY + corners[3].y * (1 - scaleY));
			newCorners[1] = new Point(corners[1].x * scaleX + corners[0].x * (1 - scaleX), corners[1].y * scaleY + corners[2].y * (1 - scaleY));
			newCorners[2] = new Point(corners[2].x * scaleX + corners[3].x * (1 - scaleX), corners[2].y * scaleY + corners[1].y * (1 - scaleY));
			newCorners[3] = new Point(corners[3].x * scaleX + corners[2].x * (1 - scaleX), corners[3].y * scaleY + corners[0].y * (1 - scaleY));
			
			homography.setTransform(qrSample, 
				newCorners[1], newCorners[0],
				newCorners[3], newCorners[2]
			);
			
			homography.x = stage.stageWidth - homography.width;
		}
		
		/**
		 *********************************************************************/
		private function onEnterFrame(e:Event):void
		{
			view.render();
		}
		
		/**
		 *********************************************************************/
		private function onMarkerFound(e:QuadTrackerEvent):void
		{
			view.scene.addChild(container);
			searchForQR();
			removeModelTimer.stop();
			removeModelTimer.reset();
		}
		
		/**
		 *********************************************************************/
		private function onMarkerLost(e:QuadTrackerEvent):void
		{
			//view.scene.removeChild(container);
			debug('MARKER LOST.  Starting timer...');
			removeModelTimer.start();
		}
		
		/**
		 *********************************************************************/
		private function onMarkerMove(e:QuadTrackerEvent):void
		{
			container.transform = fixPose3D(tracker.getPose3D());
			searchForQR();
		}
		
		/**
		 *********************************************************************/
		private function fixPose3D (m:Matrix3D):Matrix3D {
			// we must make sure that translation is always in valid range
			m.copyRawDataTo (rawPoseData);
			var scale:Number = focalLength / rawPoseData [14];
			for (var i:int = 0; i < 16; i++) {
				if (i % 4 != 3) {
					rawPoseData [i] *= scale;
				}
			}
			m.copyRawDataFrom (rawPoseData);
			// ??
			m.appendScale (-1, -1, 1);
			
			//the original and proper:
			//m.appendScale (1, -1, 1);
			//m.prependScale (-1, 1, 1);
			return m;
		}
		
		/**
		 *********************************************************************/
		private function onQrImageRead(e:QRreaderEvent):void
		{
			debug('onQrImageRead()');
			qrDecoder.setQR(e.data);
			qrDecoder.startDecode();
		}
		
		/**
		 *********************************************************************/
		private function onQrDecodeComplete(e:QRdecoderEvent):void
		{
			debug('+++++++++++ onQrDecodeComplete().  message: ' + e.data);
			
			
			//$$todo comb the array for meaningful values and determine if you have enough to ask the server
			attemptQR(e.data);
		}
		
		/**
		 *********************************************************************/
		private function onRemoveModelTimer(e:TimerEvent):void
		{
			debug('onRemoveModelTimer().  marker is lost; removing model from stage.');
			view.scene.removeChild(container);
			removeModelTimer.stop();
		}
		
		private function attemptQR(data:String):void
		{
			debug('attemptQR(' + data + ')');
			var badChars:Array = data.match(/[^a-zA-Z0-9]/gi);
			
			//We don't need you stinkin' bad characters around
			if(badChars.length) return;
			
			qrMessages[qrMessageCt++] = data;
			dispatchEvent(new KioskEvent(KioskEvent.CLEAN_QR_FOUND, {code: data}));
			
			//Search for a valid combo that occurs more than n times
			var counts:Object = {};
			var candidate:String = '';
			
			for(var i:int = 0; i < qrMessageCt && candidate == ''; i++)
			{
				if(!counts[qrMessages[i]]) counts[qrMessages[i]] = 1;
				else counts[qrMessages[i]]++;
					
				if(qrMessageThreshold <= counts[qrMessages[i]])
				{
					candidate = qrMessages[i];
					qrMessageCt = 0;
				}
			}
			
			if(candidate != '') dispatchEvent(new KioskEvent(KioskEvent.QR_CANDIDATE_FOUND, {code: candidate}));
		}
		
		/**
		 *********************************************************************/
		private function debug(msg:String):void
		{
			if(_debugging)
			{
				trace(msg);
				//msg = msg.substring(0, 55);
				//debugTrace.text = msg + '\n' + debugTrace.text;
			}
		}
	}
}
