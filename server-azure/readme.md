weather: https://gweather.azurewebsites.net/api/weather


No triggers found:
-> npm install needed packages
npm install node-fetch
npm install fs
npm install path
change node fetch require
// const fetch = require("node-fetch");
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

https://learn.microsoft.com/en-us/answers/questions/1402890/azure-function-is-not-deployed-from-vs-no-http-tri



sync triggers manually


az rest --method post --url https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Web/sites/<APP_NAME>/syncfunctiontriggers?api-version=2016-08-01

az rest --method post --url https://management.azure.com/subscriptions/945dbdc2-7d1b-4a48-a5c3-f00c0e963699/resourceGroups/gweather3/providers/Microsoft.Web/sites/gweather/syncfunctiontriggers?api-version=2024-11-01


az functionapp update --resource-group gweather3 --name gweather

Add missing to package.json




I was having similar issue - running just fine locally, deploying "sucessfully" but with "No HTTP triggers found" and without any meaningful error from Azure's part.

It turned out I was having a custom local environment variable (in local.settings.json) that was NOT present in the Function's cloud environment. Check your variables from the Portal. You can also check them from VS Code Azure Tab -> YourFunction -> Application Settings. There is also right clicking on Application Settings to Upload Local Settings.

Another issue that many people seem to have is somehow messing up your venv and using packages in your code that are not present in requirements.txt. You can try checking with pip freeze.
