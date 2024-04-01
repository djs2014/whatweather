// http server (reverse proxy on antagonist)
const http = require("http");

const https = require("https");
const axios = require('axios');
const wim = require('./services/wimage.js');
const fs = require('fs/promises');
const compression = require('compression');

const fetch = require("node-fetch");
const owm = require('./services/owm.js');
const apikeys = require('./helpers/apikeys.js');

// TODO, still not working because of apache? headers?
const API_SERVICE_URL = "https://www.ventusky.com/";
const API_SERVICE_PI_URL = "https://217.19.18.10:36477/image";
// --
const API_SERVICE_OWM_ONE_URL_2_5 = "https://api.openweathermap.org/data/2.5/onecall";
const API_SERVICE_OWM_ONE_URL_3_0 = "https://api.openweathermap.org/data/3.0/onecall";
const API_SERVICE_OWM_PARAMETERS = "&units=metric&exclude=daily";

// Express for handling GET and POST request
const express = require("express");
const app = express();
const port = process.env.PORT || 4000;

const shouldCompress = (req, res) => {
    if (req.headers['x-no-compression']) {
        return false;
    }
    return compression.filter(req, res);
};
app.use(compression({
    filter: shouldCompress,
    threshold: 0
}));

app.get('/favicon.ico', (req, res) => res.status(204).end());

app.get("/", async function (req, res) {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    var message = 'It works!\n',
        version = 'yes'; //'NodeJS ' + process.versions.node + '\n',
    response = [message, version].join('\n');
    res.end(response);
});

app.get("/image_pi", async function (req, res) {

    try {
        const queryString = req.originalUrl.split('?').splice(1).join('?');
        const uri = API_SERVICE_PI_URL + '?' + queryString;
        console.log('Process image_pi: ' + queryString);

        // authorization
        if (!req.headers.authorization) {
            res.writeHead(401);
            res.end("Unauthorized");
            console.log('Unauthorized');
            return;
        }

        let allowed = await apikeys.validApikey(req.headers.authorization);
        if (!allowed) {
            res.writeHead(403);
            res.end("Forbidden");
            console.log('Forbidden');
            return;
        }

        const httpsAgent = new https.Agent({
            rejectUnauthorized: false,
        })
        const response = await axios.get(
            uri,
            { responseType: 'arraybuffer', httpsAgent }
        );
        const image = Buffer.from(response.data, 'utf-8');
        //res.status(200).send(buffer);

        res.writeHead(200, { 'Content-Type': 'image/png' });
        res.end(image);
    } catch (err) {
        res.writeHead(500);
        res.end(err.message);
    }
});

app.get("/image", async function (req, res) {

    try {
        const queryString = req.originalUrl.split('?').splice(1).join('?');
        const uri = API_SERVICE_URL + '?' + queryString;
        console.log('Process image: ' + queryString);

        // authorization
        if (!req.headers.authorization) {
            res.writeHead(401);
            res.end("Unauthorized");
            console.log('Unauthorized');
            return;
        }

        let allowed = await apikeys.validApikey(req.headers.authorization);
        if (!allowed) {
            res.writeHead(403);
            res.end("Forbidden");
            console.log('Forbidden');
            return;
        }

        const image = await wim.getImageFromWebpage(uri);

        res.writeHead(200, { 'Content-Type': 'image/png' });
        res.end(image);
    } catch (err) {
        res.writeHead(500);
        res.end(err.message);
    }
});


app.get("/owm_one", async function (req, res) {
    try {
        const queryString = req.originalUrl.split('?').splice(1).join('?');
        console.log('Process owm_one: ' + queryString);

        // authorization
        if (!req.headers.authorization) {
            res.writeHead(401);
            res.end("Unauthorized");
            console.log('Unauthorized');
            return;
        }

        let allowed = await apikeys.validApikey(req.headers.authorization);
        if (!allowed) {
            res.writeHead(403);
            res.end("Forbidden");
            console.log('Forbidden');
            return;
        }

        // lat, lon, appid must exist
        if (!req.query.lat || !req.query.lon || !req.query.appid) {
            res.writeHead(400);
            res.end("Bad request");
            console.log('Bad request');
            return;
        }

        // default version 2.5 - old api keys
        let owmQueryString = "lat=" + req.query.lat + "&lon=" + req.query.lon +
            "&appid=" + req.query.appid;
        let uri = API_SERVICE_OWM_ONE_URL_2_5 + '?' + owmQueryString + API_SERVICE_OWM_PARAMETERS;
        if (req.query.version && req.query.version == "3.0") {
            uri = API_SERVICE_OWM_ONE_URL_3_0 + '?' + owmQueryString + API_SERVICE_OWM_PARAMETERS;
        }
        console.log('OWM uri: ' + uri);

        let getAlerts = req.query.alerts=="true";
        let maxHours = req.query.maxhours;
        let showMinutelyForecast = req.query.minutely=="true";
        let compact = req.query.proxy && req.query.proxy >= "2.0";

        // let getAlertDetails = req.query.alertdetails == "true";
        // if (getAlertDetails) {
        //     res.writeHead(200, { 'Content-Type': 'application/json' });
        //     res.end(JSON.stringify(owm.getCachedAlerts(req.query.appid, req.query.lat, req.query.lon)));
        //     return;
        // }

        let resBody = "";
        let testScenario = req.query.testScenario;
        if (testScenario) {
            try {
                console.log("use test data: " + testScenario);
                // 1: rain
                // 2: alerts
                resBody = await fs.readFile('./data/owm_sample_'+testScenario+'.json', { encoding: 'utf8' });
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(owm.convertTestdata(testScenario, req.query.appid, req.query.lat, req.query.lon,
                    resBody, maxHours, showMinutelyForecast, compact, getAlerts)));
                return;
            } catch (err) {
                console.log(err);
            }
        }

        console.log('Fetch: ' + uri);
        let fetchResp = await fetch(uri);
        resBody = await fetchResp.text();
        if (fetchResp.status != 200) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            let m = JSON.stringify(owm.convertOWMError(fetchResp.status, resBody));
            console.log('OWM response error: ' + m);
            res.end(m);
            // res.writeHead(fetchResp.status, resBody);
            // res.end(resBody);
            return;
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(owm.convertOWMdata(req.query.appid, req.query.lat, req.query.lon,
            resBody, maxHours, showMinutelyForecast, compact, getAlerts)));
    } catch (err) {
        res.writeHead(500);
        res.end(err.message);
    }
});

http.createServer(app)
    .listen(port, function (req, res) {
        console.log("Server started at port " + port);
    });
