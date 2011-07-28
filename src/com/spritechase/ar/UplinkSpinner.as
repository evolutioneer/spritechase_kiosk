package com.spritechase.ar {
	import away3d.materials.ColorMaterial;
	import away3d.materials.BitmapMaterial;
	import away3d.primitives.Plane;
	import away3d.materials.MaterialBase;

	/**
	 * @author Ross
	 */
	public class UplinkSpinner extends Plane
	{
		[Embed (source="../../../../img/establishing_uplink.png")]
		private var UplinkImage:Class;
		
		public function UplinkSpinner(material : MaterialBase = null, width : Number = 100, height : Number = 100, segmentsW : uint = 1, segmentsH : uint = 1, yUp : Boolean = true) {
			super(material, width, height, segmentsW, segmentsH, yUp);
			
			//this.material = new BitmapMaterial(new UplinkImage().bitmapData, true);
			this.material = new ColorMaterial(0xffff0000);
		}
	}
}
