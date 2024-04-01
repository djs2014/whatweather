const puppeteer = require('puppeteer');
const fs = require('fs');

const saveArrayAsFile =  (arrayBuffer, filePath)=> {
    fs.writeFile(filePath, Buffer.from(arrayBuffer), 'binary',  (err)=> {
        if (err) {
            console.log("There was an error writing the image")
        }
        else {
            console.log("Written File :" + filePath)
        }
    });const client = require('https');
};

exports.getImageFromWebpage = async function (uri) {

    let vpWidth = 320;
    let vpHeight = 568;
    let clipWidth = 280;
    let clipHeight = 300;
    let clipX = 20;
    let clipY = 60;

    let image = "";
    try {
        console.log("Getting: " + uri);
        //await(async () => {
        // const browser = await puppeteer.launch({
        //     headless: true,
        //     executablePath: '/usr/bin/chromium-browser',
        //     args: ['--no-sandbox', '--disable-setuid-sandbox']
        // });
        const browser = await puppeteer.launch();

        let page = await browser.newPage();
        // await page.goto('https://example.com');
        await page.setViewport({
            width: vpWidth,
            height: vpHeight,
            deviceScaleFactor: 1,
        });
        await page.goto(uri, {
            waitUntil: 'networkidle2',
        });
        image = await page.screenshot({
            // path: 'example.png',
            type: 'png',
            clip: {
                x: clipX,
                y: clipY,
                width: clipWidth,
                height: clipHeight
            }
        });
        console.log("Got image");
        await browser.close();        

 //       saveArrayAsFile(image, 'image.png');

        // var base64 = image.toString('base64')
        console.log("Return image bytes: " + image.length + " bytes");
        return image;
    } catch (ex) {
        console.log(ex);
    }
    return 500;
}