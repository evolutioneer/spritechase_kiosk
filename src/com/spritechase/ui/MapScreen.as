package com.spritechase.ui {
	import flash.events.MouseEvent;
	import com.spritechase.ui.UIScreen;
	import flash.display.MovieClip;

	/**
	 * @author Ross
	 */
	public class MapScreen extends UIScreen {
		
		//Stage members
		public var map_mc:MovieClip;
		public var viewport_mc:MovieClip;
		
		//Private properties
		private var minX:Number;
		private var minY:Number;
		
		public function MapScreen()
		{
			super();
		}
		
		override protected function init():void
		{
			minX = viewport_mc.width * 1.2 - map_mc.width;
			minY = viewport_mc.height * 1.2 - map_mc.height;
		}
		
		override public function focus():void
		{
			super.focus();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		override public function blur():void
		{
			super.blur();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			var distX:Number = stage.mouseX / stage.stageWidth;
			var distY:Number = stage.mouseY / stage.stageHeight;
			trace('distx, disty: ' + distX + ', ' + distY);
			
			map_mc.x = distX * minX;
			map_mc.y = distY * minY;
		}
	}
}
