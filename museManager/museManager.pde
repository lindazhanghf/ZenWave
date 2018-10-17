// OSC data streamming
import oscP5.*;
OscP5 oscP5;
int recvPort = 8980;

// Debug
boolean debug = false;
boolean debugOSC = true;

// String[] muse = {"muse_white", "muse_black"};
Muse[] muse = new Muse[2];
int id_in_use = -1; 		// The ID of the muse headband that's currently in use

// MACROS
boolean MEDITATION_MODE = true; // "true" for mediation, "false" for clam detection mode
int NUM_CHANNEL = 4;
int NUM_BAND = 5;
int BETA_BAND_ID = 1;

// State Machine
int state;
String[] state_names = {"IDLE", "FITTING", "CALIBRATION", "PREPARATION", "DETECTION", "BCI", "MEDITATION", "MEDITATION_END"};
int IDLE = 0;           // Headband not on
int FITTING = 1;        // Adjusting the headband until fitted
int CALIBRATION = 2;    // 15 seconds of calibration
int PREPARATION = 3;    // Wait for 10 seconds
int DETECTION = 4;      // Detecting 10 seconds of continuous 'calm'
int BCI = 5;            // Final state after "flipped"
int MEDITATION = 6;     // IF Meditation Mode
int MEDITATION_END = 7;

// Data
float beta_absolute;
float[] beta = new float[500]; // Store data during meditation phase
int beta_data_points;          // The number of beta data points collected duirng DETECTION / MEDITATION state

void setup() {
  oscP5 = new OscP5(this, recvPort);

  muse[0] = new Muse(0, "muse_black"); // Open the connection to "muse_black"
  muse[1] = new Muse(1, "Person0"); // Open the connection to "muse_white"

  state = MEDITATION;

  id_in_use = 0;
  println ("Using", muse[id_in_use], "headband");
}

void draw() {
	background(255);
	fill(0);

    text("Headband", 0, 15);
    text(id_in_use, 65, 15);
    if (muse[id_in_use].headband_on) text("on", 80, 15);
}

void keyReleased() {
	if (key == ENTER) {
		print("Switching: ", muse[id_in_use].name);
		swtich_headband();
		println(" ->", muse[id_in_use].name);
	}
}

void collect_meditation_data(boolean has_data) {
    if (beta_data_points >= 1000) // Data array overflow
        return;

    if (!has_data)
        beta[beta_data_points] = 0;
    else
        beta[beta_data_points] = beta_absolute;

    beta_data_points++;
}

void oscEvent(OscMessage msg) {
    if (debugOSC) {
        print("---OSC Message---");
        println(msg);
    }

    for (int id = 0; id < 2; id++) {
	    getHeadbandStatus(msg, id);

	    if (id_in_use == id) {
			boolean success = get_beta_absolute(msg, id);

			if (state == MEDITATION)
				collect_meditation_data(success);
	    }
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

boolean get_beta_absolute(OscMessage msg, int id) {
    if (msg.checkAddrPattern(muse[id].name + "/elements/beta_absolute")) {
        float result = 0;
        for (int j = 0; j < NUM_CHANNEL; j++) {
            result += get_OSC_value(msg, j);
        }
        result = result/4;

        if (!Float.isNaN(result) && result != beta_absolute) {
            beta_absolute = result;
            debugPrint("beta=" + String.valueOf(beta_absolute));
            return true;
        }
        else {
            debugPrint("beta= NaN");
            return false;
        }
    }
    return false;
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

void swtich_headband() {
	if (id_in_use != 0)
		id_in_use = 0;
	else
		id_in_use = 1;
}

//////////////////////////////////////////////////////////

class Muse {

	int id;
	String name;

	// Data
	int[] hsi_precision = new int[4];
	boolean headband_on = false;

	Muse (int _id, String headband_name) {
		id = _id;
		name = headband_name;
	}

}
