var static = require('node-static');
var fs = require('fs');
var fileServer = new static.Server('./public');

require('http').createServer(function (request, response) {
    request.addListener('end', function () {
        fileServer.serve(request, response);
    }).resume();
}).listen(8080);

var osc = require('node-osc');
var oscServer = new osc.Server(7980, '0.0.0.0');

var state_name = ["IDLE", "FITTING", "CALIBRATION", "EXPLAINATION", "MEDITATION", "BCI", "DETECTION"];
var IDLE = 0;           // Headband not on
var FITTING = 1;        // Adjusting the headband until fitted
var CALIBRATION = 2;    // 20 seconds of calibration
var EXPLAINATION = 3;   // Guide user through 3 different interactions
var DETECTION = 6;      // Detecting 10 seconds of continuous 'calm'
var BCI = 5;            // Final state after "flipped"
var MEDITATION = 4;    // IF Meditation Mode

var muse = Muse("Person0");

function Muse(name) {
    let m = {};
    m.prefix = name;
    m.in_use = false;
    m.state = -1;

    m.connection_info = [0, 0, 0, 0];
    m.baseline = [];
    m.data = [muse_data(), muse_data()];
    m.timestamps = [];
    return m;
}

oscServer.on("message", function (msg, rinfo) {
    // console.log("TUIO message:" + msg);
    if (msg[0].includes(muse.prefix)) {
        parse(muse, msg);
    }
});

function parse(muse, msg) {
    if (msg[0].includes("state")) {
        muse.state = msg[1];
        console.log(muse.prefix + " enters state " + state_name[muse.state]);

        if (muse.state == CALIBRATION) {
            muse.data = [muse_data(), muse_data()]; // reset data
        }
        if (muse.state == 5) {
            console.log(muse.data[1].array);
            // muse.baseline.push(muse.baseline[0]);

            write_data(muse);
        }
    } else if (msg[0].includes("data/baseline")) {
        // muse.baseline.push(msg[1]);
        muse.baseline.push(0.85);
        console.log("Beta baseline = " + muse.baseline[0]);
    }
    else if (muse.state == 4) {
        if (msg[0].includes("data/alpha")) {
            save_data(muse.data[0], msg);
        } else if (msg[0].includes("data/beta")) {
            save_data(muse.data[1], msg);
            muse.timestamps.push(msg[2]/10);
            muse.baseline.push(muse.baseline[0]);
        }
    }
}

/* Data osc message format: data, timestamp, is_good */
function save_data(muse_data, msg) {
    if ((msg[3]) > 2) {
        muse_data.array.push(msg[1]);
        muse_data.array_bad.push(NaN);
        // if (muse_data.prev)
        //     muse_data.array_bad.push(msg[1]);
    } else {
        muse_data.array.push(NaN);
        // muse_data.prev = {};
        muse_data.array_bad.push(msg[1]);
    }
    // muse_data.prev = msg[1];
}

function write_data(muse) {
    let content = "";
    content += "var baseline = " + JSON.stringify(muse.baseline) + ";\n";
    content += "var timestamps = " + JSON.stringify(muse.timestamps) + ";\n";
    content += "var alpha = " + JSON.stringify(muse.data[0].array) + ";\n";
    content += "var beta = " + JSON.stringify(muse.data[1].array) + ";\n";

    // write to a file named data.js to be used by html to display data
    fs.writeFile('public/data.js', content, (err) => {
        if (err) throw err;
        console.log('Write data sucess.');
        return true;
    });
    return false; // fail to write file
}

function muse_data() {
    let data = {};
    data.array = [];
    data.array_bad = []; // Array that stores the data with bad connection (not reliable)
    data.prev = {};
    return data;
}
