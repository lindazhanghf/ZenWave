var fs = require('fs');
var app = require('express')()
var http = require('http').Server(app);
var io = require('socket.io')(http);

http.listen(8888, function(){
  console.log('socket.io listening on *:8888');
});

// Run child process to refresh the charts when new data comes in
const { exec } = require('child_process');
exec('./node_modules/reload/bin/reload -p 3000 -d ./public/')

var osc = require('node-osc');
var oscServer = new osc.Server(7980, '127.0.0.1');

const debugOSC = false;
const state_name = ["IDLE", "FITTING", "CALIBRATION", "TUTORIAL", "MEDITATION", "BCI", "DETECTION"];
const IDLE = 0;           // Headband not on
const FITTING = 1;        // Adjusting the headband until fitted
const CALIBRATION = 2;    // 20 seconds of calibration
const EXPLAINATION = 3;   // Guide user through 3 different interactions
const MEDITATION = 4;     // IF Meditation Mode
const BCI = 5;            // Final state after "flipped"

// var muse_black = Muse("Muse_black", "Muse_black");  // Make sure its the same as in Muse_Manager
// var muse_white = Muse("/muse", "Muse_white");       // Make sure its the same as in Muse_Manager

var muses = [];
muses.push(Muse("Muse_black", "Muse_black"));
muses.push(Muse("/muse", "Muse_white"));
muses[0].in_use = true;

function Muse(address, prefix) {
    let m = {};
    m.address = address;
    m.prefix = prefix;
    m.in_use = false;
    m.state = 0;
    m.connection_info = [0, 0, 0, 0];
    reset_data(m);
    return m;
}

oscServer.on("message", function (msg, rinfo) {
    for (var i = 0; i < muses.length; i++) {
        if (msg[0].includes(muses[i].address))
            parse(muses[i], msg);
    }
    // if (msg[0].includes(muse_black.address)) {
    //     parse(muse_black, msg);
    // } else if (msg[0].includes(muse_white.address)) {
    //     parse(muse_white, msg);
    // }
});

io.on('connection', function(socket){
    console.log('a user connected');
    for (var i = 0; i < muses.length; i++) {
        if (muses[i].in_use)
            io.emit('toggle_on', muses[i].prefix);

        io.emit(muses[i].prefix+'_state', muses[i].state);
        io.emit(muses[i].prefix+'_connection', muses[i].connection_info);
    }
});


function parse(muse, msg) {
    if (debugOSC)
        console.log("TUIO message:" + msg);

    if (msg[0].includes("state")) {
        muse.state = msg[1];
        console.log(muse.prefix + " enters state " + state_name[muse.state]);
        io.emit(muse.prefix+'_state', muse.state);

        if (muse.state == CALIBRATION) {
            reset_data(muse);
        }
        if (muse.state == 5) {
            console.log(muse.data[1].array); // Testing
            write_data(muse);
            // io.emit('toggle_on', muse.prefix);
        }

    } else if (msg[0].includes("toggle_on")) {
        io.emit('toggle_on', muse.prefix);
        console.log("Start using ", muse.prefix);

        for (var i = 0; i < muses.length; i++) { muses[i].in_use = false; }
        muse.in_use = true;

    } else if (msg[0].includes("touching_forehead")) {
        if (muse[1] == 0) { // headband not on
            for (var i = 0; i < 4; i++) {
                muse.connection_info[i] = -1;    // bad connection
            }
        }
    } else if (msg[0].includes("horseshoe")) {
        for (var i = 0; i < 4; i++) {
            if (msg[i+1] == 4)
                muse.connection_info[i] = 0;    // bad connection
            else if (muse.address == '/muse') {
                muse.connection_info[i] = msg[i+1]==1?2:1;
            }
            else if (muse.connection_info[i] == 0 && msg[i+1] < 4)
                muse.connection_info[i] = 1;    // okay connection
        }
        io.emit(muse.prefix+'_connection', muse.connection_info);
        // console.log(muse.prefix, "IS_GOOD: ", muse.connection_info.toString())

    } else if (msg[0].includes("is_good")) {
        for (var i = 0; i < 4; i++) {
            if (msg[i+1] == 1)
                muse.connection_info[i] = 2;    // good connection
            else if (muse.connection_info[i] > 0)
                muse.connection_info[i] = 1;    // okay connection
        }
        io.emit(muse.prefix+'_connection', muse.connection_info);
        // console.log(muse.prefix, "IS_GOOD: ", muse.connection_info.toString())

    } else if (msg[0].includes("data/baseline")) {
        muse.baseline = msg[1];
        // muse.baseline = 0.85;
        console.log("Beta baseline = " + muse.baseline);
    }

    else if (muse.state == 4) { // Collecting meditation data
        let alpha = muse.data[0];
        let beta = muse.data[1];
        if (msg[0].includes("data/alpha")) {
            save_data(alpha, msg);

            let curr_beta = beta.array[beta.array.length-1].y;
            if (curr_beta != NaN && curr_beta < msg[1] && curr_beta < muse.baseline) {
                let d = {x:msg[2]/1000, y:curr_beta};
                beta.array_filled.push(d);
                muse.num_relaxed++;
                return;
            } else if (curr_beta != NaN) // Don't count the points if the user is moving (NaN)
                muse.num_alert++;

            beta.array_filled.push({x: msg[2]/1000, y: NaN});

        } else if (msg[0].includes("data/beta")) {
            save_data(beta, msg);
            // muse.timestamps.push(msg[2]/1000); // In seconds
            muse.baseline_array.push({x: msg[2]/1000, y: muse.baseline});
        }
    }
}

/* Data osc message format: data, timestamp, is_good */
function save_data(muse_data, msg) {
    if ((msg[3]) > 2) {
        muse_data.array.push({x: msg[2]/1000, y: msg[1]});
    } else {
        muse_data.array.push({x: msg[2]/1000, y: NaN});
    }

    muse_data.array_dashed.push({x: msg[2]/1000, y: msg[1]});
    console.log("Save data - ", msg[1]);
}

function write_data(muse) {
    let content = "";
    // content += "var timestamps = " + JSON.stringify(muse.timestamps) + ";\n";
    content += "var baseline = " + JSON.stringify(muse.baseline_array) + ";\n";
    let alpha = muse.data[0];
    content += "var alpha = " + JSON.stringify(alpha.array) + ";\n";
    content += "var alpha_dashed = " + JSON.stringify(alpha.array_dashed) + ";\n";
    let beta = muse.data[1];
    content += "var beta = " + JSON.stringify(beta.array) + ";\n";
    content += "var beta_dashed = " + JSON.stringify(beta.array_dashed) + ";\n";
    content += "var beta_filled = " + JSON.stringify(beta.array_filled) + ";\n";
    let valid_data = (muse.num_alert + muse.num_relaxed) / 1000; // To calculate percentage [Meditation Result]
    content += "var result = " + JSON.stringify([Math.round(muse.num_relaxed/valid_data)/10, Math.round(muse.num_alert/valid_data)/10]) + ";\n";
    console.log("Meditation result: ", muse.num_alert, muse.num_relaxed);

    // content += "var headband_in_use = " + JSON.stringify(muse.prefix) + ";\n";
    // for (var i = 0; i < muses.length; i++) {
    //     content += "var " + muse.prefix + "_connection = " + JSON.stringify(muses.connection_info) + ";\n";
    // }

    // write to a file named data.js to be used by html to display data
    fs.writeFile('public/data.js', content, (err) => {
        if (err) throw err;
        console.log('Write data sucess.');
        return true;
    });
    return false; // fail to write file
}

function write_connection_info() {
    let content = "";
    content += "var connection_muse_black = " + JSON.stringify(muse_black.connection_info) + ";\n";
    content += "var connection_muse_white = " + JSON.stringify(muse_white.connection_info) + ";\n";
    // write to a file named connection_info.js to be used by html to display data
    fs.writeFile('public/connection_info.js', content, (err) => {
        if (err) throw err;
        console.log('Write data sucess.');
        return true;
    });
    return false; // fail to write file
}

function reset_data(muse) {
    muse.baseline = 0;
    muse.baseline_array = [];
    muse.data = [muse_data(), muse_data()];
    muse.num_alert = 0;
    muse.num_relaxed = 0;
}

function muse_data() {
    let data = {};
    data.array = [];
    data.array_dashed = [];
    data.array_filled = []; // Periods that the user achieved a state of peace
    return data;
}
