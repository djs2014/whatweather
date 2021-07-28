import Toybox.Lang;
import Toybox.System;

class UvPoint {
	public var x;
	public var y;
	public var isHidden;
	public var uvi;
	
	public function initialize( x as Number, uvi as Number) {
      self.x = x;
      self.uvi = uvi;      
      y = uvi;        
      self.isHidden = false; 
    } 
    public function calculateVisible(precipitationChance) {
      self.isHidden = (uvi <= $._hideUVIndexLowerThan) && (precipitationChance > 0);
      //System.println("hidden " + isHidden + " uvi " + uvi + " hideuv " + $._hideUVIndexLowerThan + " pop " +  precipitationChance);
    }
    
    public function info() {
    	return Lang.format("UvPoint: x[$1$] y[$2$] isHidden[$3$]",[x, y, isHidden]);   
    }
}