package com.spritechase.ui {
	import com.spritechase.ui.UIScreen;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;

	/**
	 * @author Ross
	 */
	public class IdleScreen extends UIScreen {
		
		public var menu_mc:MovieClip;
		
		public function IdleScreen() {
			super();
		}
		
		override protected function init():void
		{
			stop();
			
			for(var i:int = 0; i < menu_mc.numChildren; i++)
			{
				if(menu_mc.getChildAt(i) is SimpleButton) SimpleButton(menu_mc.getChildAt(i)).addEventListener(MouseEvent.CLICK, onMenuClick);
			}
		}
		
		private function onMenuClick(e:MouseEvent):void
		{
			var btn:SimpleButton = e.currentTarget as SimpleButton;
			gotoAndStop(btn.name.replace('_btn', ''));
		}
		
		override public function idle():void
		{
			
		}
	}
}
