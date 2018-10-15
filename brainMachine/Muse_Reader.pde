/* Muse Headband Reader by Linda Zhang */

//////////////////////////////////////////////////////

// Debug
boolean debug = false;
boolean debugOSC = false;

// OSC data streamming
import oscP5.*;
String muse_name = "muse"; // "muse" default setting; "/muse" if via Muse Monitor app
int recvPort = 8980;
OscP5 oscP5;

// MACROS
boolean MEDITATION_MODE = true; // "true" for mediation, "false" for clam detection mode
int CALM_TIME = 5;   // How many consecutive seconds of calm time must be detected before entering A.I state
int MEDITATION_TIME = 60; // Length of the meditation time in seconds, default 60 seconds
int NUM_CHANNEL = 4;
int NUM_BAND = 5;
String[] BANDS = {"alpha", "beta", "gamma", "delta", "theta", "EEG"};
color[] COLORS = {#E0FFFF, #FF5733, #F4D03F, #B0A94F, #82E0AA, #000000};
int RECT_HEIGHT = 200;
int RECT_WIDTH = 50;
int BASELINE_HEIGHT = 500;
int DIAGRAM_LEFT_LIMIT = 20;

// Bands
int ALPHA = 0;
int BETA = 1;
int GAMMA = 2;
int DELTA = 3;
int THETA = 4;

// States
String[] state_names = {"IDLE", "FITTING", "CALIBRATION", "PREPARATION", "DETECTION", "BCI", "MEDITATION", "MEDITATION_END"};
int IDLE = 0;           // Headband not on
int FITTING = 1;        // Adjusting the headband until fitted
int CALIBRATION = 2;    // 15 seconds of calibration
int PREPARATION = 3;    // Wait for 10 seconds
int DETECTION = 4;      // Detecting 10 seconds of continuous 'calm'
int BCI = 5;            // Final state after "flipped"

int MEDITATION = 6;    // IF Meditation Mode
int MEDITATION_END = 7;

// Data
int[] hsi_precision = new int[4];
float[] relative = new float[5];
float[] absolute = new float[5];
float[] score = new float[5];
float[] eeg = new float[4];
boolean[] good_connection = new boolean[4];
boolean headband_on = false;
boolean has_data = false;
float[] beta = new float[1000]; // Collects data during meditation phase

// Audio File
SoundFile calibration_done;

// Calibration & Detection
float beta_upper_limit = 0.3; // Calculated by average of of Beta absolute band power during CALIBRATION state
float beta_sum;               // Sum of Beta absolute band power during CALIBRATION state
int calibration_data_points;  // The number of beta data points collected duirng CALIBRATION state
int beta_data_points;         // The number of beta data points collected duirng DETECTION / MEDITATION state
int curr_time;

// State Machine
int state = IDLE;
int calm_start_time = -1;
int state_start_time = -1;
int time_since_calibrating = -1;

// Visualization
int last_reset_time = -1;    // Keep track of when the rest brain (position of neurons)
int rect_height = 0;
int rect_x = 0;
float diagram_bottom_y = 0;
float diagram_left = 0;
boolean randomly_moving = false;

void setup_Muse_Reader() {
  oscP5 = new OscP5(this, recvPort);
  calibration_done = new SoundFile (this, "success.wav");

  curr_time = current_time();
  last_reset_time = curr_time;
}

void draw_Muse_Reader() {
    curr_time = current_time();
    fill(0);

    // State Machine
    switch (state) {
        case 2: // CALIBRATION
            time_since_calibrating =  curr_time - state_start_time;
            if (time_since_calibrating > 20 && calibration_data_points > 70)
                changeState(PREPARATION);
            // changeState(PREPARATION); //TODO testing only
            break;

        case 3: // PREPARATION
            if (curr_time - state_start_time > 5) // Wait 5 seconds before starting the detection
                changeState(MEDITATION_MODE ? MEDITATION : DETECTION);
            break;

        case 6: // MEDITATION
            if (curr_time - state_start_time > MEDITATION_TIME)
                changeState(BCI); // TODO MEDITATION_END
            break;
        default: break;
    }

    if ((curr_time - state_start_time) % 5 == 0)
        randomly_moving = false;

    // Testing
    text("State:", 800, 15);
    text(state_names[state], 900, 15);
    text(beta_upper_limit, 900,25);
    if (calm_start_time > 0) text(curr_time - calm_start_time, 900,40);
    else text(curr_time - state_start_time, 900,40);
    text(calibration_data_points, 930, 40);
    text("#data " + beta_data_points, 900, 55);

    for (int i = 0; i < 4; i++)
        text((good_connection[i]?"good":"bad"), 10, 10 + i * 15);

    // Draw bar chart
    if (state == BCI) {
        if (MEDITATION_MODE)
            visualize_meditation();
        else
            visualizeData(score);
    }
    else
        visualizeData(absolute);
        // visualizeData(eeg);
}

void resetBrain() { // DEBUG
    idleChange = true;
    last_reset_time = curr_time;
    idleReset();
}

void changeState(int new_state) {
    // Old State
    if (state == CALIBRATION) {
        calibration_done.play();
        // Calculate average beta band from calibration
        beta_upper_limit = beta_sum / calibration_data_points;
        // if (beta_upper_limit < 0.1 || Float.isNaN(beta_upper_limit))
        //     beta_upper_limit = 0.1;
        println("Beta Upper Limit = ", beta_upper_limit);

        // For visualizing meditation result
        diagram_bottom_y = BASELINE_HEIGHT + beta_upper_limit * RECT_HEIGHT * 2;
        println ("rect y = ", diagram_bottom_y);
    }

    if (new_state == IDLE) {
        resetBrain();
        artBrainLoop.stop();
        humBrainLoop.stop();
        rectY = 200;
    }
    else if (new_state == BCI) {
        humBrainLoop.stop();
        artBrainLoop.loop(1);
        rectY = 50;
    }
    else if (new_state == CALIBRATION) {
        humBrainLoop.loop(1);
    }
    else if (new_state == PREPARATION) {
        resetBrain();
    }

    println("Change to new state: ", state_names[new_state]);
    state = new_state;
    state_start_time = curr_time;
}


void oscEvent(OscMessage msg) {
    if (debugOSC) {
        print("---OSC Message---");
        println(msg);
    }

    randomly_moving = true;
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

/* Meditation Visualization */
void visualize_meditation() {
    float _x = 0, x = 0, y = 0;
    float _y = Float.NaN;

    fill(0);
    stroke(0);
    background(255);
    for (int i = 0; i < beta_data_points; i++) {
        x = i + DIAGRAM_LEFT_LIMIT;

        if (Float.isNaN(beta[i]))
            y = Float.NaN;
        else
            y = diagram_bottom_y - beta[i] * RECT_HEIGHT * 2;

        // Only draw this line signment if there's  data
        if (!Float.isNaN(_y)) {
            line(_x, _y, x, y);
        }
        _x = x;
        _y = y;
    }

    stroke(COLORS[0]);
    line(DIAGRAM_LEFT_LIMIT, BASELINE_HEIGHT, DIAGRAM_LEFT_LIMIT + beta_data_points, BASELINE_HEIGHT);


    stroke(0);
    text(beta_upper_limit, x, BASELINE_HEIGHT);
    text(beta[beta_data_points-1], x, y);
    text("0", x, diagram_bottom_y);
}

void collect_meditation(boolean has_beta_data) {
    if (beta_data_points >= beta.length) // Data array overflow
        return;

    if (!has_beta_data)
        beta[beta_data_points] = Float.NaN;
    else
        beta[beta_data_points] = absolute[BETA];

    beta_data_points++;
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
        beta_data_points++;

        if (calm_start_time < 0)
            calm_start_time = curr_time; // Reset start_time

        else if (curr_time - calm_start_time > CALM_TIME // 'Calm' for 10 seconds
            && beta_data_points > calibration_data_points) // Enough datapoints were collected before making the switch
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
    beta_data_points = 0;
}

/* Headband Status Information (fitting precision) */
void getHeadbandStatus(OscMessage msg) {
    if (msg.checkAddrPattern(muse_name + "/elements/touching_forehead")
        && (msg.checkTypetag("i")))
    {
        // debugPrint("Touching forehead? " + String.valueOf(msg.get(0).intValue()) + "\n");
        if (msg.get(0).intValue() == 1) {
            headband_on = true;
            if (state == IDLE)
                changeState(FITTING);
        } else {
            headband_on = false;
            if (state != IDLE)
                changeState(IDLE);
        }
    }

    if (state > IDLE && msg.checkAddrPattern(muse_name + "/elements/horseshoe"))
    {
        int sum_precision = 0;
        for (int i=0; i< NUM_CHANNEL; i++) {
            hsi_precision[i] = (int)get_OSC_value(msg, i);
            sum_precision += hsi_precision[i];
            if (hsi_precision[i] > 2)
                calm_start_time = -1; // Not fitted, restart calm detection
        }

        // if (state ==  FITTING && sum_precision == 4) // 4 means all fitted
        //     changeState(CALIBRATION);
    }

    // Strict data quality indicator for each channel, 0= bad, 1 = good
    if (state > IDLE && msg.checkAddrPattern(muse_name + "/elements/is_good"))
    {
        boolean is_good = true;
        for (int i=0; i< NUM_CHANNEL; i++) {
            good_connection[i] = get_OSC_value(msg, i) == 1; // 1 for true; 0 for false
            if (good_connection[i] == false) {
                calm_start_time = -1; // Bad connection, restart calm detection
                is_good = false;
            }
        }

        if (state ==  FITTING && is_good) // 4 means all fitted
            changeState(CALIBRATION);
    }
}

/* Absolute Band Power */
void getAbsolute(OscMessage msg) {
    has_data = get_elements_data(msg, "absolute", absolute);

    if (state == MEDITATION && msg.checkAddrPattern(muse_name + "/elements/beta_absolute"))
        collect_meditation(has_data);

    if (has_data && msg.checkAddrPattern(muse_name + "/elements/beta_absolute")) {
        if (state == DETECTION)
            detect_calmness();
        else if (state == CALIBRATION && time_since_calibrating > 10)
        {
            beta_sum += absolute[BETA];
            calibration_data_points++;
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

/* Get OSC data within the "elements" category */
boolean get_elements_data(OscMessage msg, String element_name, float[] data_array) {
    for (int i = 0; i < BANDS.length; i++) {
        if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + element_name)) {
            float sum = 0;
            for (int j = 0; j < NUM_CHANNEL; j++) {
                sum += get_OSC_value(msg, j);
            }
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
    for (int i = 0; i < 5; i++) {
        if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + element_name)) {
            data_array[i] = msg.get(0).floatValue();
            debugPrint("  " + BANDS[i] + "=" + String.valueOf(data_array[i]) + "\n");
            break;
        }
    }
    return true;
}

/* EEG */
void getEEG(OscMessage msg){
    if (msg.checkAddrPattern(muse_name + "/eeg")) {
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
    if (msg.checkAddrPattern(muse_name + "/elements/blink")) {
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
