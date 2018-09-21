/* Muse Headband Reader by Linda Zhang */

//////////////////////////////////////////////////////

// OSC Library
import oscP5.*;

boolean debug = false;

//OSC
String muse_name = "muse"; // Muse's default setting
int recvPort = 7980;
OscP5 oscP5;

// MACROS
int NUM_CHANNEL = 4;
int NUM_BAND = 5;
String[] BANDS = {"alpha", "beta", "gamma", "delta", "theta"};
color[] COLORS = {#E0FFFF, #FF5733, #F4D03F, #B0A94F, #82E0AA};
int RECT_HEIGHT = 200;

// Bands
int ALPHA = 0;
int BETA = 1;
int GAMMA = 2;
int DELTA = 3;
int THETA = 4;

// States
String[] state_names = {"IDLE", "FITTING", "CALIBRATION", "PREPARATION", "DETECTION", "BCI"};
int IDLE = 0;         // Headband not on
int FITTING = 1;      // Adjusting the headband until fitted
int CALIBRATION = 2;  // 15 seconds of calibration
int PREPARATION = 3;  // Wait for 10 seconds
int DETECTION = 4;    // Detecting 10 seconds of continuous 'calm'
int BCI = 5;          // Final state after "flipped"

// Data
int[] hsi_precision = new int[4];
float[] relative = new float[5];
float[] absolute = new float[5];
float[] score = new float[5];

// Audio File
SoundFile success;

// Visualization
int rect_x = 0;
int rect_y = 0;
int rect_height = 0;
int rect_width = 50;

// State Machine
int state = IDLE;
int calm_start_time = -1;

// for testing
float beta_upper_limit = 0.3;
int time_since_detected = -1;

void draw_Muse_Reader() {
    // background(255,255,255);
    fill(0);
    for (int i=0; i< NUM_CHANNEL; i++) {
        // text(String.valueOf(i), 10, 10 + 10 * i);
        text(String.valueOf(hsi_precision[i]), 30, 25 + 10 * i);
    }

    // testing
    text(state_names[state], 5, 15);
    switch (state) {
        case 4:
            if (time_since_detected>0) println(time_since_detected);
            break;
        default: break;
    }

    visualizeAbsolute();

}

void changeState(int new_state) {
    if (new_state == DETECTION)
    {
        // currentState = 1;
    }
    else if (new_state == BCI)
    {
        rectY = 50;
    }

    println("Change to new state: ", state_names[new_state]);

    state = new_state;
}


void oscEvent(OscMessage msg) {
    /* print the address path and the type string of the received OscMessage */
    if (debug) {
        print("---OSC Message---");
        println(msg);
    }

    getHeadbandStatus(msg);


    switch (state)
    {
        case 1:
        case 2:
        case 3:
        case 4:
            getAbsolute(msg);
            getScore(msg);
            break;

        default :
            break;
    }
}

void visualizeAbsolute() {
    // Absolute Graph
    for (int i = 0; i < NUM_BAND; i++) {
        rect_x = 50 + i * 100;

        fill(COLORS[i]);
        rect_height = (int)((absolute[i] * RECT_HEIGHT));
        rect(rect_x, 420-rect_height, rect_width, rect_height); // Draw the rect at y=420

        fill(0);
        text(BANDS[i], rect_x, 420+10);
        text(String.valueOf((float)absolute[i]), rect_x, 420+22); // Print data
    }
}

void detect_calmness() {
    if (absolute[ALPHA] > absolute[BETA])
    {
        int curr_time = current_time();

        if (calm_start_time < 0)
            calm_start_time = curr_time; // Reset start_time

        else if (curr_time - calm_start_time > 10) { // 'Calm' for 10 seconds
            changeState(BCI);
            success.play();
        }

        //test
        else {
            time_since_detected = curr_time - calm_start_time;
            // println(minute(), ":", second());
        }
    }
    else {
        calm_start_time = -1;
    }

    if (absolute[BETA] > beta_upper_limit) {
        calm_start_time = -1;
    }
}

/* Headband Status Information (precision) */
void getHeadbandStatus(OscMessage msg) {
    if (msg.checkAddrPattern(muse_name + "/elements/touching_forehead")
        && (msg.checkTypetag("i")))
    {
        debugPrint("Touching forehead? " + String.valueOf(msg.get(0).intValue()));
        if (msg.checkTypetag("i") && msg.get(0).intValue() == 1) {
            if (state == IDLE)
                changeState(FITTING);
        } else {
            changeState(IDLE);
        }
    }
    // else
    //     debugPrint("No headband status.");

    if (state > IDLE && msg.checkAddrPattern(muse_name + "/elements/horseshoe")==true)
    {
        int sum_precision = 0; // 4 means all fitted
        for (int i=0; i< NUM_CHANNEL; i++) {
            hsi_precision[i] = (int)get_OSC_value(msg, i);
            sum_precision += hsi_precision[i];
            if (hsi_precision[i] > 2)
                calm_start_time = -1;
        }

        if (state ==  FITTING && sum_precision == 4)
            changeState(DETECTION); // TODO: skipped CALIBRATION    s
    }
    // else
    //     debugPrint(" No horseshoe status\n");
}

/* Absolute Band Power */
void getAbsolute(OscMessage msg) {
    boolean success = get_elements_data(msg, "absolute", absolute);

    if (success && state == DETECTION)
        detect_calmness();
}

/* Relative Band Power */
void getRelative(OscMessage msg) {
    get_elements_data(msg, "relative", relative);
}

/* Band Power Score */
void getScore(OscMessage msg) {
    boolean success = get_elements_data(msg, "session_score", score); // TODO: score
    if (!success)
        return;

    // for (int i = 0; i < 5; i++) {
    //     if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + "session_score")) {
    //         println(" " + BANDS[i] + "=" + String.valueOf(score[i]));
    //         break;
    //     }
    // }
}

boolean get_elements_data(OscMessage msg, String element_name, float[] data_array) {
    // float[] result_data = new float[5];
    for (int i = 0; i < 5; i++) {
        if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + element_name)) {
            float sum = 0;
            for (int j = 0; j < NUM_CHANNEL; j++) {
                sum += get_OSC_value(msg, j);
            }
            debugPrint("  " + BANDS[i] + "=" + String.valueOf(sum) + "\n");

            if (!Double.isNaN(sum)) {
                data_array[i] = sum/4;
                debugPrint(" " + BANDS[i] + "=" + String.valueOf(data_array[i]));
            }
            else {
                debugPrint(" " + BANDS[i] + "  NaN");
                return false; // sum is NaN (not a number)
            }
            break;
        }
    }
    return true; // sum is a number
}

/* Blink */
void getBlink(OscMessage msg) {
    if (msg.checkAddrPattern(muse_name + "/elements/blink")==true) {
        print("\nBlink ");
        if (msg.checkTypetag("i")) {
            print(msg.get(0).intValue());
        } else
            print("Type unknown");
    }
}

int current_time() {
    return (hour() * 60 + minute()) * 60 + second();
}

// get float value from "ffff" or "dddd" type OSC data
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
