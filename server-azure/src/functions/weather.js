const { app } = require("@azure/functions");
// const fetch = require("node-fetch");
const fetch = (...args) => import("node-fetch").then(({ default: fetch }) => fetch(...args));

const owm = require("../services/owm.js");
const apikeys = require("../helpers/apikeys.js");
const testScenarioHandler = require("../helpers/testscenarios.js");

const API_SERVICE_OWM_ONE_URL_2_5 = "https://api.openweathermap.org/data/2.5/onecall";
const API_SERVICE_OWM_ONE_URL_3_0 = "https://api.openweathermap.org/data/3.0/onecall";
const API_SERVICE_OWM_PARAMETERS = "&units=metric&exclude=daily";

app.http("weather", {
  methods: ["GET", "POST"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    context.log(`Http function processed request for url "${request.url}"`);

    // const name = request.query.get('name') || await request.text() || 'world';
    // return { body: `Hello, ${name}!` };

    try {
      // const queryString = request.url.split('?').splice(1).join('?');
      const queryString = request.query;
      context.log("Process owm_one: " + queryString);

      // authorization

      let authorization = request.headers.get("authorization");
      if (!authorization) {
        context.log("Unauthorized");
        return { status: 401 };
      }

      let allowed = await apikeys.validApikey(authorization);
      if (!allowed) {
        context.log("Forbidden for " + request.headers.authorization);
        return { status: 403 };
      }

      const searchParams = new URLSearchParams(queryString);

      if (searchParams.has("testScenario")) {
        let scenario = searchParams.get("testScenario");
        let maxHoursTest = searchParams.get("maxhours");
        let appidTest = searchParams.get("appid");
        try {
          context.log("use test data set: " + scenario);
          let testJson = await testScenarioHandler.getTestScenario(appidTest, scenario, maxHoursTest);
          if (testJson) {
            return {
              jsonBody: testJson,
            };
          }
        } catch (err) {
          context.log(err);
        }
      }

      // lat, lon, appid must exist
      if (!searchParams.has("lat") || !searchParams.has("lon") || !searchParams.has("appid")) {
        context.log("Bad request");
        return { status: 400 };
      }

      let lat = searchParams.get("lat");
      let lon = searchParams.get("lon");
      let appid = searchParams.get("appid");
      let version = "";
      if (searchParams.has("version")) {
        version = searchParams.get("version");
      }

      // default version 2.5 - old api keys
      let owmQueryString = "lat=" + lat + "&lon=" + lon + "&appid=" + appid;
      let uri = API_SERVICE_OWM_ONE_URL_2_5 + "?" + owmQueryString + API_SERVICE_OWM_PARAMETERS;
      if (version == "3.0") {
        uri = API_SERVICE_OWM_ONE_URL_3_0 + "?" + owmQueryString + API_SERVICE_OWM_PARAMETERS;
      }
      context.log("OWM uri: " + uri);

      let getAlerts = searchParams.get("alerts") == "true";
      let maxHours = searchParams.get("maxhours");
      let showMinutelyForecast = searchParams.get("minutely") == "true";
      // let windGust = req.query.windgust=="true";
      let compact = searchParams.get("proxy") >= "2.0";

      // let getAlertDetails = req.query.alertdetails == "true";
      // if (getAlertDetails) {
      //     res.writeHead(200, { 'Content-Type': 'application/json' });
      //     res.end(JSON.stringify(owm.getCachedAlerts(req.query.appid, req.query.lat, req.query.lon)));
      //     return;
      // }

      let resBody = "";

      context.log("Fetch: " + uri);
      let fetchResp = await fetch(uri);
      resBody = await fetchResp.text();
      if (fetchResp.status != 200) {
        let m = JSON.stringify(owm.convertOWMError(fetchResp.status, resBody));
        context.log("OWM response error: " + m);
        return {
          jsonBody: m,
        };
      }

      // let json = JSON.stringify(owm.convertOWMdata(appid, lat, lon, resBody, maxHours, showMinutelyForecast, compact, getAlerts));
      let data = owm.convertOWMdata(appid, lat, lon, resBody, maxHours, showMinutelyForecast, compact, getAlerts);
      return {
        status: 200,
        jsonBody: data,
      };
    } catch (err) {
      context.log("App error: " + err);
      return {
        jsonBody: err.message,
      };
    }
  },
});
