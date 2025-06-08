const { promises: { readFile } } = require("fs");
const path = require("path");

const owm = require("../services/owm.js");

let getTestScenario = async function (appid, scenario, maxHours) {
    if (!scenario) {
        return "";
    }
        console.log("Current directory:", __dirname);

        // TODO -> owm output samples
        // get strong wind example
        let scenarioFile = '../data/owm_sample_' + scenario + '.json';
        let json = {};
        await readFile(path.resolve(__dirname,scenarioFile)).then(fileBuffer => {
            // console.log(fileBuffer.toString());
            // let testdata = JSON.parse(fileBuffer.toString());
            let testdata = fileBuffer.toString();

            let lat = 42.0;
            let lon = scenario;
            json = owm.convertTestdata(scenario, appid, lat, lon, testdata, maxHours, true, true, true);

            // json.lat = 42.0;
            // json.lon = scenario;
            // Set correct time in seconds (var seconds = new Date().getTime() / 1000;)
            // json.current.dt = Date.now() / 1000;
            // json.current.tz_offset = 0;

            // let dateObject = new Date();
            // dateObject.setMinutes(0);
            
            // for(var i = 0; i< json.hourly.length; i++) {
            //     dateObject.setTime(dateObject.getTime()+ (i*60*60*1000));
            //     json.hourly[i][0] = dateObject.getTime() / 1000;
            // }
        }).catch(error => {
            console.error(error.message);
            return "";
        });
        return json;    
}

exports.getTestScenario = async function (appid, scenario, maxHours) {   
    return await getTestScenario(appid, scenario, maxHours);
}