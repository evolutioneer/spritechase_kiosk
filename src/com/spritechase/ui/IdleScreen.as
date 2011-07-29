package com.spritechase.ui {
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import com.spritechase.ui.UIScreen;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;

	/**
	 * @author Ross
	 */
	public class IdleScreen extends UIScreen {
		
		//Stage members
		public var menu_mc:MovieClip;
		public var marquee_mc:MovieClip;
		
		//Private members
		private var loopTimer:Timer;
		
		
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
			
			//$$testme init the loop timer
			loopTimer = new Timer(10000, 0);
			loopTimer.addEventListener(TimerEvent.TIMER, onLoopTimer);
			loopTimer.start();
		}
		
		private function onLoopTimer(e:TimerEvent):void
		{
			play();
		}
		
		private function resetLoopTimer(e:Event = null):void
		{
			loopTimer.reset();
		}
		
		private function onMenuClick(e:MouseEvent):void
		{
			var btn:SimpleButton = e.currentTarget as SimpleButton;
			gotoAndStop(btn.name.replace('_btn', ''));
		}
		
		override public function idle():void
		{
			
		}
		
		override public function focus():void
		{
			super.focus();
			loopTimer.start();
			addEventListener(MouseEvent.MOUSE_MOVE, resetLoopTimer);
		}
		
		override public function blur():void
		{
			super.blur();
			loopTimer.stop();
			removeEventListener(MouseEvent.MOUSE_MOVE, resetLoopTimer);
		}
	}
}
