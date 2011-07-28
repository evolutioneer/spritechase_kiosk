﻿package com.spritechase.ui{	import flash.events.Event;	import flash.display.MovieClip;	import flash.display.DisplayObject;	import flash.events.MouseEvent;	import flash.utils.Timer;	import flash.events.TimerEvent;		import com.spritechase.core.*;		import com.greensock.TweenLite;		public class KioskUI extends MovieClip	{		//Public properties		public var debug:Boolean = false;				//Stage members		public var screens_mc:MovieClip;		public var play_btn:PlayButton;		public var title_mc:UITitle;		public var scanMe_mc:MovieClip;		public var indicator_mc:MovieClip;				//Private properties		private var data:KioskData;		private var screenIndex:int = 0;		private var screenCt:int = 0;		private var currentScreen:UIScreen;		private var screenOrder:Array =		[			'idle',			'video',			'user',			'map',			'leader'		];				public function KioskUI()		{			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);			trace("KioskUI()");		}				private function onAddedToStage(e:Event):void		{			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);			screenCt = screens_mc.numChildren;		}				public function init(newData:KioskData):void		{			trace('KioskUI.init().  Data: ' + newData.data.toXMLString());			data = newData;						//Iterate over all screens and update their data from the kiosk data object			for(var i:int = 0; i < screens_mc.numChildren; i++)			{				var child:DisplayObject = screens_mc.getChildAt(i);				if(child is UIScreen)				{					UIScreen(child).update(data);					UIScreen(child).blur();				}			}						//Bind event listeners on play button to invoke changeScreen			play_btn.addEventListener(MouseEvent.CLICK, nextScreen);			play_btn.enabled = true;			title_mc.visible = true;			play_btn.visible = true;			scanMe_mc.visible = false;			screens_mc.alpha = 1;			screens_mc.visible = true;			nextScreen();		}				public function nextScreen(e:MouseEvent = null):void		{			trace('nextScreen()');			//UIScreen(screens_mc.getChildAt(screenIndex)).blur();						if(currentScreen) currentScreen.blur();			screenIndex++;			if(screenIndex == screenCt) screenIndex = 0;						//Get the current UI screen's info			currentScreen = UIScreen(screens_mc.getChildByName(screenOrder[screenIndex] + '_mc'));			currentScreen.focus();						var screenName:String = currentScreen.name.substr(0, -3);						//update title on main page			trace("Updating title for screen: " + screenName);			title_mc.update(screenName);						//update carousel indicator to reflect new position 			indicator_mc.gotoAndStop(screenName);						//tween screens			TweenLite.to(screens_mc, 0.5, {				x: -1 * currentScreen.x			});		}				public function onHandshakeAttempt(e:KioskEvent = null):void		{			TweenLite.to(screens_mc, 0.25, {alpha: 0});			TweenLite.to(scanMe_mc, 0.25, {alpha: 0});		}				public function idle():void		{			trace('idle()');						//unbind all event handlers on the play button			play_btn.removeEventListener(MouseEvent.CLICK, nextScreen);			play_btn.enabled = false;			title_mc.visible = false;			play_btn.visible = false;			scanMe_mc.visible = true;			scanMe_mc.alpha = 1;			screens_mc.alpha = 1;						//iterate over all screens and tell them to discard their user-specific data			for(var i:int = 0; i < screens_mc.numChildren; i++)			{				var child:DisplayObject = screens_mc.getChildAt(i);				if(child is UIScreen) UIScreen(child).idle();			}						//show idle overlay content						screenIndex = -1;			nextScreen();		}					}}