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

var muse = Muse("Person0");

function Muse(name) {
    let m = {};
    m.prefix = name;
    m.in_use = false;
    m.state = -1;

    m.connection_info = [0, 0, 0, 0];
    m.baseline = [];
    m.data = [muse_data(), muse_data()];
    return m;
}

oscServer.on("message", function (msg, rinfo) {
    console.log("TUIO message:");
    console.log(msg);
    if (msg[0].includes(muse.prefix)) {
        parse(muse, msg);
    }
});

function parse(muse, msg) {
    if (msg[0].includes("state")) {
        muse.state = msg[1];
        console.log(muse.state);
        return;
    }
    if (muse.state == 4) {
        if (msg[0].includes("data/baseline"))
            muse.data_alpha.push({x: baseline, y: msg[2]});
        if (msg[0].includes("data/alpha")) {
            save_data(muse.data[0], msg);
        } else if (msg[0].includes("data/beta")) {
            save_data(muse.data[1], msg);
        }
    }
    else if (muse.state == 5) {
            muse.data_alpha.push(muse.baseline[0]);
    }
}


function save_data(muse_data, msg) {
    let d = {x: msg[1], y: msg[2]};
    if ((msg[3]) > 2) {
        muse_data.array.push(d);
        // muse_data.prev = d;
        // if (muse_data.prev)
        //     muse_data.array_bad.push(d);
    } else {
        muse_data.array.push({x: msg[1], y: NaN});
        // muse_data.prev = {};
        muse_data.array_bad.push(d);
    }

}

function muse_data() {
    let data = {};
    data.array = [];
    data.array_bad = []; // Array that stores the data with bad connection (not reliable)
    data.prev = {};
    return data;
}
