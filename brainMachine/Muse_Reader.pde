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
int CALM_TIME = 5; // How many consecutive seconds of calm time must be detected before entering A.I state
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
boolean headband_on = false;

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
int calibration_start_time = -1;

// for testing
float beta_upper_limit = 0.3; // Calculated by average of of Beta absolute band power during calibration
int time_since_detected = -1;
int time_since_calibrating = -1;
float beta_sum;               // Sum of Beta absolute band power during calibration state
int beta_data_points;         // The number of beta data points collected
int last_reset_time = -1;
int curr_time;

void setup_Muse_Reader() {
  oscP5 = new OscP5(this, recvPort);
  success = new SoundFile (this, "success.wav");

  curr_time = current_time();
  last_reset_time = curr_time;
}

void draw_Muse_Reader() {
    curr_time = current_time();
    fill(0);

    // testing
    text("State:", 800, 15);
    text(state_names[state], 900, 15);
    switch (state) {
        case 2: // CALIBRATION
            time_since_calibrating =  curr_time - calibration_start_time;
            println("Calibration: ", time_since_calibrating, " seconds;   ");
            if (time_since_calibrating > 20)
                changeState(PREPARATION);
            break;
        case 3: // PREPARATION
            if (time_since_calibrating > 5) // Wait 5 seconds before starting the detection
                changeState(DETECTION);
            break;
        case 4: // DETECTION
            text(beta_upper_limit, 900,25);
            if (time_since_detected>0) println(time_since_detected, "   ", beta_upper_limit);
            break;
        default: break;
    }

    // visualizeAbsolute();

    // reset neurons
    if (curr_time - last_reset_time > 60) {
        idleReset();
        last_reset_time = curr_time;
    }
}

void changeState(int new_state) {
    idleReset();

    if (new_state == CALIBRATION) {
        humBrainLoop.loop(1);
        calibration_start_time = curr_time;
    }

    else if (new_state == PREPARATION) {
        calibration_start_time = curr_time;
    }

    else if (new_state == DETECTION) {
        success.play();
        beta_upper_limit = beta_sum / beta_data_points;
        if (beta_upper_limit < 0.1 || Float.isNaN(beta_upper_limit))
            beta_upper_limit = 0.1;
        println("Beta Upper Limit = ", beta_upper_limit, " !!!!!!!!!!!!!!!!!");
    }

    else if (new_state == BCI)
        rectY = 50;

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
        case 2: // CALIBRATION
            getAbsolute(msg);
            break;

        case 4: // DETECTION
            getAbsolute(msg);
            getScore(msg);
            break;

        default :
            get_elements_data(msg, "relative", absolute);
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
        if (calm_start_time < 0)
            calm_start_time = curr_time; // Reset start_time

        else if (curr_time - calm_start_time > CALM_TIME) { // 'Calm' for 10 seconds
            changeState(BCI);
        }

        // test
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
            headband_on = true;
            if (state == IDLE)
                changeState(FITTING);
        } else {
            headband_on = false;
            changeState(IDLE);
        }
    }

    if (state > IDLE && msg.checkAddrPattern(muse_name + "/elements/horseshoe")==true)
    {
        int sum_precision = 0; // 4 means all fitted
        for (int i=0; i< NUM_CHANNEL; i++) {
            hsi_precision[i] = (int)get_OSC_value(msg, i);
            sum_precision += hsi_precision[i];
            if (hsi_precision[i] > 2)
                calm_start_time = -1;                   // Not fitted, restart calm detection
        }

        if (state ==  FITTING && sum_precision == 4)
            changeState(CALIBRATION);

    }
}

/* Absolute Band Power */
void getAbsolute(OscMessage msg) {
    boolean success = get_elements_data(msg, "absolute", absolute);

    if (success && state == DETECTION)
        detect_calmness();
    else if (success && state == CALIBRATION && msg.checkAddrPattern(muse_name + "/elements/beta_absolute") && time_since_calibrating > 10)
    {
        beta_sum += absolute[BETA];
        beta_data_points++;
    }
}

/* Relative Band Power */
void getRelative(OscMessage msg) {
    get_elements_data(msg, "relative", relative);
}

/* Band Power Score */
void getScore(OscMessage msg) {
    get_elements_data(msg, "session_score", score);
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
