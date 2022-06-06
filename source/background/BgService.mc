import Toybox.Lang;

(:background)
class BGService {
    const ERROR_BG_NONE as Number = 0;      
    const ERROR_BG_NO_API_KEY as Number = -1;
    
    const ERROR_BG_NO_PROXY as Number = -3; // @@ Not yet used
    const ERROR_BG_EXCEPTION as Number = -4;
    const ERROR_BG_EXIT_DATA_SIZE_LIMIT as Number = -5;
    const ERROR_BG_INVALID_BACKGROUND_TIME as Number = -6; // @@ Not yet used
    const ERROR_BG_NOT_SUPPORTED as Number = -7;
    const ERROR_BG_HTTPSTATUS as Number = -10;

    const ERROR_BG_NO_POSITION as Number = -2;
    const ERROR_BG_NO_PHONE as Number = -8;
    const ERROR_BG_GPS_LEVEL as Number = -9;

    const HTTP_OK as Number = 200;
}