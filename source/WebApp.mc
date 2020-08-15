using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Position;

const URL = "http://192.168.43.91";

class WebApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
        
    }
    
    var myCount =  0;
    function timerCallback() {
        makeRequest();
        myCount += 1;
        Ui.requestUpdate();
    }

    // onStart() is called on application start up
    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        var myTimer = new Timer.Timer();
        myTimer.start(method(:timerCallback), 5000, true);
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new WebView("Starting " + URL) ];
    }
    
    function onPosition(info) {
        var gps = Position.getInfo();
        Sys.println(gps);
	}
    
    
    function getPosition() {
        var lat = null;
        var long = null;
        var positionInfo = Activity.getActivityInfo().currentLocation;
        if (positionInfo != null) {
            lat= positionInfo.toDegrees()[0];
            long = positionInfo.toDegrees()[1];
        }
        return [lat, long];
    }
    
    function getHeartRate() {
        var heartRateText = "000";
        var currentHeartRate = Activity.getActivityInfo().currentHeartRate;
        if(currentHeartRate != null) {
            heartRateText = currentHeartRate;
        }
        else {
            var heartRateHistory = ActivityMonitor.getHeartRateHistory(1, true); //newestFirst = true
            var heartRateSample = heartRateHistory.next();
            var heartRate = heartRateSample.heartRate;
            
            if(heartRateSample == ActivityMonitor.INVALID_HR_SAMPLE) {
                heartRateText = "---";
            }
            else {
                heartRateText = heartRate;
            }
            System.println( "Heart Rate: " + heartRateText );
        }
        return heartRateText;
    }
    
    
    function getCurrentSpeed() {
        var spd = 0;
        var info = Activity.getActivityInfo();
        spd = info.currentSpeed;
        return spd;
    }
    
    function getPower() {
        var stats = Sys.getSystemStats();
        var pwr = stats.battery;
        var batStr = Lang.format( "$1$%", [ pwr.format( "%2d" ) ] );
        return pwr;
    }
    
    function onReceive(responseCode, data) {
        Ui.switchToView(new WebView("onReceive: " + URL + "\n" + responseCode + " " + data), null, Ui.SLIDE_IMMEDIATE);
    }
    
    function makeRequest() {
        var url = URL;
        var pos = getPosition();
        var hbr = getHeartRate();
        var myrand = Math.rand() % 100 + 1;
        var params = {
            "lat" => pos[0],
            "long" => pos[1],
            "heart beat" => hbr,
            "random" => myrand,
            "speed" => getCurrentSpeed(),
            "battery" => getPower()
        };
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        var responseCallback = method(:onReceive);

        Communications.makeWebRequest(url, params, options, method(:onReceive));
    }
}
