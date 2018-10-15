// OSC data streamming
import oscP5.*;
OscP5 oscP5;
int recvPort = 8980;

// Debug
boolean debug = false;
boolean debugOSC = true;

// String[] muse = {"muse_white", "muse_black"};
Muse[] muse = new Muse[2];

// MACROS
boolean MEDITATION_MODE = true; // "true" for mediation, "false" for clam detection mode
int NUM_CHANNEL = 4;
int NUM_BAND = 5;

void setup() {
  oscP5 = new OscP5(this, recvPort);

  muse[0] = new Muse(0, "muse_black"); // Open the connection to "muse_black"
  muse[1] = new Muse(1, "Person0"); // Open the connection to "muse_white"
}

void draw() {
	background(255);
	fill(0);

    text("Headband:", 0, 15);
    if (muse[1].headband_on) text("on", 80, 15);
}

void oscEvent(OscMessage msg) {
    if (debugOSC) {
        print("---OSC Message---");
        println(msg);
    }

    for (int id = 0; id < 2; id++) {
	    getHeadbandStatus(msg, id);
    }
}

/* Headband Status Information (fitting precision) */
void getHeadbandStatus(OscMessage msg, int id) {
    if (msg.checkAddrPattern(muse[id].name + "/elements/touching_forehead")
        && (msg.checkTypetag("i")))
    {
        muse[id].headband_on = (msg.get(0).intValue() == 1);
    }

    if (msg.checkAddrPattern(muse[id].name + "/elements/horseshoe"))
    {
        int sum = 0;
        for (int i=0; i< NUM_CHANNEL; i++) {
            muse[id].hsi_precision[i] = (int)get_OSC_value(msg, i);
            sum += muse[id].hsi_precision[i];
        }

        // if (sum == 4) // 4 means all fitted
        //     changeState(CALIBRATION);

    }
}

/* get float value from "ffff" or double value from "dddd" OSC data */
float get_OSC_value(OscMessage msg, int index) {
    if (msg.checkTypetag("ffff"))
        return msg.get(index).floatValue();
    if (msg.checkTypetag("dddd"))
        return (float)msg.get(index).doubleValue();

    debugPrint("Type unknown" + "\n");
    return Float.NaN;
}

/* Debug helper */
void debugPrint(String s) {
    if (debug) print(s);
}

//////////////////////////////////////////////////////////

class Muse {

	int id;
	String name;
	boolean in_use = false;

	// Data
	int[] hsi_precision = new int[4];
	boolean headband_on = false;

	Muse (int _id, String headband_name) {
		id = _id;
		name = headband_name;
	}

}