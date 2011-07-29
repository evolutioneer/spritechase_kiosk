package com.spritechase.ui {
	import com.spritechase.core.KioskData;
	import flash.text.TextField;
	import com.spritechase.ui.UIScreen;

	/**
	 * @author Ross
	 */
	public class LeaderScreen extends UIScreen {
		
		public var playersLabel_txt:TextField;
		public var teamsLabel_txt:TextField;
		public var players_txt:TextField;
		public var teams_txt:TextField;
		public var ranks_txt:TextField;
		public var instructions_txt:TextField;
		
		public function LeaderScreen() {
			super();
		}
		
		override public function update(data:KioskData):void
		{
			super.update(data);
		
			var section:XMLList = data.data..section.(@id == 'leader');
			
			teams_txt.text = section.list.(@id == 'teams').children().toString().replace(/(<br\/>|\r|\n)+/gi, '\n');
			players_txt.text = section.list.(@id == 'users').children().toString().replace(/(<br\/>|\r|\n)+/gi, '\n');
			
			//$$debug wtf, why is this not working
			trace('+++ teams_txt: ' + teams_txt.text);
			trace('+++ playerss_txt: ' + players_txt.text);
		}
	}
}
