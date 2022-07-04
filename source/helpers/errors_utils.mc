import Toybox.System;
import Toybox.Communications;
import Toybox.Lang;

(:background)
module CommunicationsHelpers {

    class CustomErrors {
      public const ERROR_BG_NO_API_KEY = -9000;
      public const ERROR_BG_NO_POSITION = -9001;
      public const ERROR_BG_NO_PROXY = -9002;
      public const ERROR_BG_EXCEPTION = -9003;
      public const ERROR_BG_EXIT_DATA_SIZE_LIMIT = -9004;
      public const ERROR_BG_INVALID_BACKGROUND_TIME = -9005;  
    }

    function getCommunicationError(error as Lang.Number?) as String {
          if (error == null) {return "";}
          if (error == Communications.UNKNOWN_ERROR) {return "Unknown";}
          if (error == Communications.BLE_ERROR) {return "BLE error";}
          if (error == Communications.BLE_HOST_TIMEOUT) {return "BLE host timeout";}
          if (error == Communications.BLE_SERVER_TIMEOUT) {return "BLE server timeout";}
          if (error == Communications.BLE_NO_DATA) {return "BLE no data";}
          if (error == Communications.BLE_REQUEST_CANCELLED) {return "BLE req canceled";}
          if (error == Communications.BLE_QUEUE_FULL) {return "BLE queue full";}
          if (error == Communications.BLE_REQUEST_TOO_LARGE) {return "BLE req too large";}
          if (error == Communications.BLE_UNKNOWN_SEND_ERROR) {return "BLE unkown send err";}
          if (error == Communications.BLE_CONNECTION_UNAVAILABLE) {return "BLE conn. unavailable";}
          if (error == Communications.INVALID_HTTP_HEADER_FIELDS_IN_REQUEST) {return "HPPT invalid req headers";}
          if (error == Communications.INVALID_HTTP_BODY_IN_REQUEST) {return "HTTP invalid req body";}
          if (error == Communications.INVALID_HTTP_METHOD_IN_REQUEST) {return "HTTP invalid req method";}
          if (error == Communications.NETWORK_REQUEST_TIMED_OUT) {return "Network req timeout";}
          if (error == Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE) { return "HTTP invalid resp body";}
          if (error == Communications.INVALID_HTTP_HEADER_FIELDS_IN_NETWORK_RESPONSE) {return "HTTP invalid resp headers";}
          if (error == Communications.NETWORK_RESPONSE_TOO_LARGE) {return "HTTP resp too large";}
          if (error == Communications.NETWORK_RESPONSE_OUT_OF_MEMORY) {return "HTTP resp out of memory";}
          if (error == Communications.STORAGE_FULL) {return "Storage full";}
          if (error == Communications.SECURE_CONNECTION_REQUIRED) {return "Secure connection required";}
          if (error == Communications.UNSUPPORTED_CONTENT_TYPE_IN_RESPONSE) {return "HTTP unsupported content-type";}
          if (error == Communications.REQUEST_CANCELLED) {return "HTTP req canceled";}
          if (error == Communications.REQUEST_CONNECTION_DROPPED) {return "HTTP conn dropped";}
          if (error == Communications.UNABLE_TO_PROCESS_MEDIA) {return "Unable to process media";}
          if (error == Communications.UNABLE_TO_PROCESS_IMAGE) {return "Unable to process image";}
          if (error == Communications.UNABLE_TO_PROCESS_HLS) {return "Unable to process HLS";}

          if (error == CustomErrors.ERROR_BG_NO_API_KEY) {return "No API key";}
          if (error == CustomErrors.ERROR_BG_NO_POSITION) {return "No position";}
          if (error == CustomErrors.ERROR_BG_NO_PROXY) {return "No proxy";}
          if (error == CustomErrors.ERROR_BG_EXCEPTION) {return "Exception";}
          if (error == CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT) {return "Response too large";}
          if (error == CustomErrors.ERROR_BG_INVALID_BACKGROUND_TIME) {return "Invalid bg time";}

        return error.format("%d");
      }
}