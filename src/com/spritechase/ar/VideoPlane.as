package com.spritechase.ar

{
	import away3d.primitives.Plane;
	import away3d.materials.BitmapMaterial;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.media.Video;
	import qtrack.QuadTracker;

	public class VideoPlane extends Plane
	{
		/**
		 *********************************************************************/
		public function VideoPlane (tracker:QuadTracker, distance:Number) {
			bd = new BitmapData (nextPowerOf2 (tracker.width), nextPowerOf2 (tracker.height), false, 0);
			m = new Matrix (bd.width / tracker.width, 0, 0, bd.height / tracker.height);
			if (tracker.mirrored) { m.a *= -1; m.tx = bd.width; }
			super (new BitmapMaterial (bd, true, false, false), 1, 1);
			tracker.addEventListener (Event.ENTER_FRAME, updateMaterial);
			transform = tracker.makePlaneTransform (distance);
		}
	
		/**
		 *********************************************************************/
		private function updateMaterial (e:Event):void {
			bd.lock ();
			bd.draw (Video (e.target), m, null, null, null, true);
			BitmapMaterial (material).updateTexture ();
			bd.unlock ();
		}
		
		/**
		 *********************************************************************/
		private function nextPowerOf2 (n:Number, max_p:Number = 512):int {
			var p:int = 2; while ((p < n) && (p < max_p)) p *= 2; return p;
		}
	
		private var bd:BitmapData, m:Matrix;
	}
}
