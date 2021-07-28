import Toybox.Lang;
import Toybox.Test;
import Toybox.System;
using Toybox.Application.Storage;

function getStringStorage(key, dflt) {
    Test.assert(dflt instanceof Lang.String);
	try {
        var val = Storage.getValue(key);
        if (val != null && val instanceof Lang.String && !"".equals(val)) {
            return val;
        }
	} catch (e) {
    	return dflt;
    } 	    
    return dflt;
}

function getBooleanStorage(key, dflt) {
    return getTypedStorage(key, dflt, Lang.Boolean);
}

function getNumberStorage(key, dflt) {
    return getTypedStorage(key, dflt, Lang.Number);
}

function getFloatStorage(key, dflt) {
    return getTypedStorage(key, dflt, Lang.Float);
}

function getDoubleStorage(key, dflt) {
    return getTypedStorage(key, dflt, Lang.Double);
}

function getTypedStorage(key, dflt, type) {
    Test.assert(dflt instanceof type);

	try {
        var val = Storage.getValue(key);
        if (val != null && val instanceof type) {
            return val;
        }		
	} catch (e) {
    	return dflt;
    } 	    
    return dflt;
}

function setStorage(key, value) {
	Storage.setValue(key, value);	    
}