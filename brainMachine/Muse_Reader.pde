/* Muse Headband Reader by Linda Zhang */

//////////////////////////////////////////////////////

// OSC Library
import oscP5.*;

boolean debug = false;
boolean debugOSC = false;

//OSC
String muse_name = "muse"; // "muse" default setting; "/muse" if via Muse Monitor app
int recvPort = 8980;
OscP5 oscP5;

// MACROS
int CALM_TIME = 5; // How many consecutive seconds of calm time must be detected before entering A.I state
int NUM_CHANNEL = 4;
int NUM_BAND = 5;
String[] BANDS = {"alpha", "beta", "gamma", "delta", "theta", "EEG"};
color[] COLORS = {#E0FFFF, #FF5733, #F4D03F, #B0A94F, #82E0AA, #000000};
int RECT_HEIGHT = 200;
int RECT_WIDTH = 50;

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
float[] eeg = new float[4];
boolean headband_on = false;
boolean has_data = false;

// Audio File
SoundFile success;

// Calibration & Detection
float beta_upper_limit = 0.3; // Calculated by average of of Beta absolute band power during CALIBRATION
float beta_sum;               // Sum of Beta absolute band power during CALIBRATION state
int calibration_data_points;         // The number of beta data points collected duirng CALIBRATION state
int detection_data_points;         // The number of beta data points collected duirng DETECTION state
int last_reset_time = -1;
int curr_time;

// State Machine
int state = IDLE;
int calm_start_time = -1;
int calibration_start_time = -1;
int time_since_calibrating = -1;
int preparation_start_time = -1;

// Visualization
int rect_x = 0;
int rect_height = 0;


void setup_Muse_Reader() {
  oscP5 = new OscP5(this, recvPort);
  success = new SoundFile (this, "success.wav");

  curr_time = current_time();
  last_reset_time = curr_time;
}

void draw_Muse_Reader() {
    // println("FrameRate =", frameRate);
    curr_time = current_time();
    fill(0);

    // testing
    text("State:", 800, 15);
    text(state_names[state], 900, 15);
    switch (state) {
        case 2: // CALIBRATION
            time_since_calibrating =  curr_time - calibration_start_time;
            // println("Calibration: ", time_since_calibrating, " seconds;   ");
            if (time_since_calibrating > 20 && calibration_data_points > 70)
                changeState(PREPARATION);
            // changeState(DETECTION); // TODO
            break;
        case 3: // PREPARATION
            if (curr_time - preparation_start_time > 5) // Wait 5 seconds before starting the detection
                changeState(DETECTION);
            break;
        case 4: // DETECTION
            break;
        default: break;
    }
    text(beta_upper_limit, 900,25);
    if (calm_start_time > 0) text(curr_time - calm_start_time, 900,40);
    text(calibration_data_points, 930, 40);
    text("#data " + detection_data_points, 900, 55);

    // reset neurons every 1 minute
    if (state < BCI && curr_time - last_reset_time > 60) {
        resetBrain();
        last_reset_time = curr_time;
    }

    // Visualizations
    // visualizeData(eeg);
    if (state == BCI)
        visualizeData(score);
    else
        visualizeData(absolute);
}

void resetBrain() {
    // idleChange = true;
    // idleReset();
}

void changeState(int new_state) {
    if (new_state == IDLE) {
        humBrainLoop.stop();
        rectY = 200;
    }
    else if (new_state == BCI)
        rectY = 50;
    else if (new_state == CALIBRATION) {
        // resetBrain();
        humBrainLoop.loop(1);
        calibration_start_time = curr_time;
    }

    else if (new_state == PREPARATION) {
        resetBrain();
        success.play();
        preparation_start_time = curr_time;
    }

    else if (new_state == DETECTION) {
        resetBrain();
        // Calculate results from calibration
        beta_upper_limit = beta_sum / calibration_data_points;
        if (beta_upper_limit < 0.1 || Float.isNaN(beta_upper_limit))
            beta_upper_limit = 0.1;
        println("Beta Upper Limit = ", beta_upper_limit, " !!!!!!!!!!!!!!!!!");
    }

    println("Change to new state: ", state_names[new_state]);

    state = new_state;
}


void oscEvent(OscMessage msg) {
    /* print the address path and the type string of the received OscMessage */
    if (debugOSC) {
        print("---OSC Message---");
        println(msg);
    }

    getHeadbandStatus(msg);
    // getEEG(msg);

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
            getAbsolute(msg);
            getScore(msg);
            break;
    }
}

/* Visualization Bar Chart */
void visualizeData(float[] data_array) {
    for (int i = 0; i < data_array.length; i++) {
        rect_x = 550 + i * 100;

        fill(COLORS[i]);
        rect_height = (int)((data_array[i] * RECT_HEIGHT));

        // Draw the bars at y=700
        rect(rect_x, 700 - rect_height / 2, RECT_WIDTH, rect_height);

        fill(0);
        text(BANDS[i], rect_x - RECT_WIDTH / 2, 700 + 10);
        text(String.valueOf((float)data_array[i]), rect_x - RECT_WIDTH / 2, 700 + 22);
    }
}

void detect_calmness() {
    if (absolute[BETA] > beta_upper_limit) {
        reset_detection();
        return;
    }

    if (absolute[ALPHA] > absolute[BETA])
    {
        detection_data_points++;

        if (calm_start_time < 0)
            calm_start_time = curr_time; // Reset start_time

        else if (curr_time - calm_start_time > CALM_TIME // 'Calm' for 10 seconds
            && detection_data_points > calibration_data_points) // Enough datapoints were collected before making the switch
        {
            changeState(BCI);
        }
    }
    else {
        reset_detection();
    }
}

void reset_detection() {
    calm_start_time = -1;
    detection_data_points = 0;
}

/* Headband Status Information (precision) */
void getHeadbandStatus(OscMessage msg) {
    if (msg.checkAddrPattern(muse_name + "/elements/touching_forehead")
        && (msg.checkTypetag("i")))
    {
        // debugPrint("Touching forehead? " + String.valueOf(msg.get(0).intValue()) + "\n");
        if (msg.checkTypetag("i") && msg.get(0).intValue() == 1) {
            headband_on = true;
            if (state == IDLE)
                changeState(FITTING);
        } else {
            headband_on = false;
            if (state != IDLE)
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
    has_data = get_elements_data(msg, "absolute", absolute);

    if (has_data && msg.checkAddrPattern(muse_name + "/elements/beta_absolute")) {
        if (state == DETECTION){
            detect_calmness();
        }
        else if (state == CALIBRATION && time_since_calibrating > 10)
        {
            beta_sum += absolute[BETA];
            calibration_data_points++;
            // println(absolute[BETA]);
        }
    }
}

/* Band Power Score */
void getScore(OscMessage msg) {
    get_elements_data(msg, "session_score", score);
}

/* Relative Band Power */
void getRelative(OscMessage msg) {
    get_elements_data(msg, "relative", relative);
}

boolean get_elements_data(OscMessage msg, String element_name, float[] data_array) {
    // float[] result_data = new float[5];
    for (int i = 0; i < BANDS.length; i++) {
        if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + element_name)) {
            float sum = 0;
            for (int j = 0; j < NUM_CHANNEL; j++) {
                sum += get_OSC_value(msg, j);
            }
            // debugPrint("  " + BANDS[i] + "=" + String.valueOf(sum) + "\n");
            sum = sum/4;

            if (!Float.isNaN(sum) && sum != data_array[i]) {
                data_array[i] = sum;
                debugPrint(" " + BANDS[i] + "=" + String.valueOf(data_array[i]));
                return true;
            }
            else {
                debugPrint(" " + BANDS[i] + "  NaN");
                return false;
            }
        }
    }
    return false;
}

boolean get_elements_data_muse_monitor(OscMessage msg, String element_name, float[] data_array) {
    // float[] result_data = new float[5];
    for (int i = 0; i < 5; i++) {
        if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + element_name)) {

            data_array[i] = msg.get(0).floatValue();
            debugPrint("  " + BANDS[i] + "=" + String.valueOf(data_array[i]) + "\n");
            // if (!Double.isNaN(sum)) {
            //     debugPrint(" " + BANDS[i] + "=" + String.valueOf(data_array[i]));
            // }
            // else {
            //     debugPrint(" " + BANDS[i] + "  NaN");
            //     return false; // sum is NaN (not a number)
            // }
            break;
        }
    }
    return true;
}

/* EEG */
void getEEG(OscMessage msg){
    if (msg.checkAddrPattern(muse_name + "/eeg")==true) {
            // print("\nEEG ");
            if (msg.checkTypetag("dddddd")) {
                for (int i=0; i < 4; i++) {
                    eeg[i] = (float)msg.get(i).doubleValue()/1000;
                }
            } else if (msg.checkTypetag("ffffff")) {
                for (int i=0; i < 4; i++) {
                    eeg[i] = msg.get(i).floatValue()/1000;
                }
            } else
                print("Type unknown");
    }
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
