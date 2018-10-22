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
    m.baseline = 0;
    m.baseline_array = [];
    m.data = [muse_data(), muse_data()];
    m.timestamps = [];
    return m;
}

oscServer.on("message", function (msg, rinfo) {
    console.log("TUIO message:" + msg);
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
            muse.baseline = 0;
            muse.baseline_array = [];
        }
        if (muse.state == 5) {
            console.log(muse.data[1].array); // Testing
            write_data(muse);
        }
    } else if (msg[0].includes("data/baseline")) {
        muse.baseline = 0.85;
        console.log("Beta baseline = " + muse.baseline);
    }
    else if (muse.state == 4) {
        let alpha = muse.data[0];
        let beta = muse.data[1];
        if (msg[0].includes("data/alpha")) {
            save_data(alpha, msg);

            if (beta.array_dashed[beta.array_dashed.length-1] < msg[1] //alpha.array_dashed[alpha.array_dashed.length-1]
                && beta.array_dashed[beta.array_dashed.length-1] < muse.baseline)
                beta.array_filled.push(beta.array_dashed[beta.array_dashed.length-1]);
            else
                beta.array_filled.push(NaN);
        } else if (msg[0].includes("data/beta")) {
            save_data(beta, msg);
            muse.timestamps.push(msg[2]/10); // In seconds
            muse.baseline_array.push(muse.baseline);
        }
    }
}

/* Data osc message format: data, timestamp, is_good */
function save_data(muse_data, msg) {
    if ((msg[3]) > 2) {
        muse_data.array.push(msg[1]);
    } else {
        muse_data.array.push(NaN);
    }

    muse_data.array_dashed.push(msg[1]);
}

function write_data(muse) {
    let content = "";
    content += "var timestamps = " + JSON.stringify(muse.timestamps) + ";\n";
    content += "var baseline = " + JSON.stringify(muse.baseline_array) + ";\n";
    let alpha = muse.data[0];
    content += "var alpha = " + JSON.stringify(alpha.array) + ";\n";
    content += "var alpha_dashed = " + JSON.stringify(alpha.array_dashed) + ";\n";
    let beta = muse.data[1];
    content += "var beta = " + JSON.stringify(beta.array) + ";\n";
    content += "var beta_dashed = " + JSON.stringify(beta.array_dashed) + ";\n";
    content += "var beta_filled = " + JSON.stringify(beta.array_filled) + ";\n";

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
    data.array_dashed = [];
    data.array_filled = []; // Periods that the user achieved a state of peace
    return data;
}
