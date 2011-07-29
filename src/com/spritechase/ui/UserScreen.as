package com.spritechase.ui {
	import flash.text.TextField;
	import com.spritechase.core.KioskData;
	import com.spritechase.ui.UIScreen;

	/**
	 * @author Ross
	 */
	public class UserScreen extends UIScreen {
		
		//Stage members
		public var name_txt:TextField;
		public var parts_txt:TextField;
		public var projects_txt:TextField;
		public var projectsLabel_txt:TextField;
		public var partsLabel_txt:TextField;
		
		public function UserScreen() {
			super();
		}
		
		override public function update(data:KioskData):void
		{
			super.update(data);
			trace('UserScreen.update()');
			
			var section:XMLList = data.data..section.(@id == 'user');
			
			name_txt.text = section.child('name');
			parts_txt.text = section.parts;
			projects_txt.text = section.projects;
		}
	}
}
