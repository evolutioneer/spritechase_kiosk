/**
 * @author zeh, original idea
 * @author makc, inverted transform
 * @see http://zehfernando.com/2010/the-best-drawplane-distortimage-method-ever/
 */
package com.spritechase.ar
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	public class Homography extends Shape {
	    private var v6:Vector.<int> = Vector.<int> ([0, 1, 2, 0, 2, 3]);
	    private var v8:Vector.<Number> = new Vector.<Number> (8, true);
	    private var v12:Vector.<Number> = new Vector.<Number> (12, true);
	
	    public function setTransform (src:BitmapData,
	        p0:Point, p1:Point, p2:Point, p3:Point,
	        destWidth:int = 100, destHeight:int = 100):void {
	
	        // Find diagonals intersection point
	        var pc:Point = new Point;
	
	        var a1:Number = p2.y - p0.y;
	        var b1:Number = p0.x - p2.x;
	        var a2:Number = p3.y - p1.y;
	        var b2:Number = p1.x - p3.x;
	
	        var denom:Number = a1 * b2 - a2 * b1;
	        if (denom == 0) {
	            // something is better than nothing
	            pc.x = 0.25 * (p0.x + p1.x + p2.x + p3.x);
	            pc.y = 0.25 * (p0.y + p1.y + p2.y + p3.y);
	        } else {
	            var c1:Number = p2.x * p0.y - p0.x * p2.y;
	            var c2:Number = p3.x * p1.y - p1.x * p3.y;
	            pc.x = (b1 * c2 - b2 * c1) / denom;
	            pc.y = (a2 * c1 - a1 * c2) / denom;
	        }
	
	        // Lengths of first diagonal
	        var ll1:Number = Point.distance(p0, pc);
	        var ll2:Number = Point.distance(pc, p2);
	
	        // Lengths of second diagonal
	        var lr1:Number = Point.distance(p1, pc);
	        var lr2:Number = Point.distance(pc, p3);
	
	        // Ratio between diagonals
	        var f:Number = (ll1 + ll2) / (lr1 + lr2);
	
	        var sw:Number = src.width, sh:Number = src.height;
	        var dw:Number = destWidth, dh:Number = destHeight;
	
	        v8 [2] = dw; v8 [4] = dw; v8 [5] = dh; v8 [7] = dh;
	
	        v12 [0] = p0.x / sw; v12 [ 1] = p0.y / sh; v12 [ 2] = ll2 / f;
	        v12 [3] = p1.x / sw; v12 [ 4] = p1.y / sh; v12 [ 5] = lr2;
	        v12 [6] = p2.x / sw; v12 [ 7] = p2.y / sh; v12 [ 8] = ll1 / f;
	        v12 [9] = p3.x / sw; v12 [10] = p3.y / sh; v12 [11] = lr1;
	
	        graphics.clear ();
	        graphics.beginBitmapFill (src, null, false, true);
	        graphics.drawTriangles (v8, v6, v12);
	        
	        
	    }
	}
}