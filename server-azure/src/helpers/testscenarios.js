const { promises: { readFile } } = require("fs");
const path = require("path");

let getTestScenario = async function (scenario) {
    if (!scenario) {
        return "";
    }
        console.log("Current directory:", __dirname);

        let scenarioFile = '../data/proxy_sample_' + scenario + '.json';
        let json = {};
        await readFile(path.resolve(__dirname,scenarioFile)).then(fileBuffer => {
            // console.log(fileBuffer.toString());
            json = JSON.parse(fileBuffer.toString());

            // Set correct time in seconds (var seconds = new Date().getTime() / 1000;)
            json.current.dt = Date.now() / 1000;
            json.current.tz_offset = 0;

            let dateObject = new Date();
            dateObject.setMinutes(0);
            
            for(var i = 0; i< json.hourly.length; i++) {
                dateObject.setTime(dateObject.getTime()+ (i*60*60*1000));
                json.hourly[i][0] = dateObject.getTime() / 1000;
            }
        }).catch(error => {
            console.error(error.message);
            return "";
        });
        return json;    
}

exports.getTestScenario = async function (scenario) {   
    return await getTestScenario(scenario);
}