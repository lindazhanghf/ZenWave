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
int IDLE = 0;         // Headband not on
int FITTING = 1;      // Adjusting the headband until fitted
int CALIBRATION = 2;  // 15 seconds of calibration
int PREPARATION = 3;  // Wait for 10 seconds
int DETECTION = 4;    // Detecting 10 seconds of continuous 'calm'
int BCI = 5;          // Final state after "flipped"

// Data
int[] hsi_precision = new int[4];
double[] relative = new double[5];
double[] absolute = new double[5];

// Audio File
SoundFile success;

// Visualization
int rect_x = 0;
int rect_y = 0;
int rect_height = 0;
int rect_width = 50;

// State Machine
int state = IDLE;
int detection_start_time = -1;

// for testing
double beta_upper_limit = 0.3;
int time_since_detecting = -1;

void draw_Muse_Reader() {
    // background(255,255,255);
    fill(0);
    for (int i=0; i< NUM_CHANNEL; i++) {
        // text(String.valueOf(i), 10, 10 + 10 * i);
        text(String.valueOf(hsi_precision[i]), 30, 25 + 10 * i);
    }

    // testing
    switch (state) {
        case 0: text("IDLE", 5, 15); break;
        case 1: text("FITTING", 5, 15); break;
        case 2: text("CALIBRATION", 5, 15); break;
        case 3: text("PREPARATION", 5, 15); break;
        case 4: text("DETECTION", 5, 15);
            if (time_since_detecting>0) println(time_since_detecting);
            break;
        default : text("BCI", 5, 15); break;
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

    print("Change to new state:");
    switch (new_state) {
        case 0: println("IDLE"); break;
        case 1: println("FITTING"); break;
        case 2: println("CALIBRATION"); break;
        case 3: println("PREPARATION"); break;
        case 4: println("DETECTION"); break;
        default : println("BCI"); break;
    }

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
        case 4:
            getAbsolute(msg);

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

void detect_calmness(OscMessage msg) {
    if (absolute[ALPHA] > absolute[BETA])
    {
        int curr_time = current_time();

        if (detection_start_time < 0)
            detection_start_time = curr_time; // Reset start_time

        else if (curr_time - detection_start_time > 1) { // 'Calm' for 10 seconds
            changeState(BCI);
            success.play();
        }

        //test
        else {
            time_since_detecting = curr_time - detection_start_time;
            // println(minute(), ":", second());
        }
    }
    else {
        detection_start_time = -1;
    }

    if (absolute[BETA] > beta_upper_limit) {
        detection_start_time = -1;
    }
}

/* EEG */
void getEEG(OscMessage msg){
    if (msg.checkAddrPattern(muse_name + "/eeg")==true) {
            // print("\nEEG ");
            if (msg.checkTypetag("dddddd")) {
                for (int i=0; i< NUM_CHANNEL; i++) {
                    // print("  [",i,"]", msg.get(i).doubleValue());
                }
            } else
                print("Type unknown");
    }
}

/* Headband Status Information (precision) */
void getHeadbandStatus(OscMessage msg) {
    if (msg.checkAddrPattern(muse_name + "/elements/touching_forehead")
        && (msg.checkTypetag("i")))
    {
        debugPrint("Touching forehead? " + String.valueOf(msg.get(0).intValue()));
        if (msg.checkTypetag("i") && msg.get(0).intValue() == 1)
        {
            if (state == IDLE)
                changeState(FITTING);
        }
        else
        {
            changeState(IDLE);
        }
    }
    else
        debugPrint("No headband status.");

    if (state > IDLE && msg.checkAddrPattern(muse_name + "/elements/horseshoe")==true)
    {
        boolean is_double = true;
        if (msg.checkTypetag("dddd")) {
            is_double = true;
        } else if (msg.checkTypetag("ffff")) {
            is_double = false;
        } else {
            print("Type unknown");
            return;
        }

        int sum_precision = 0; // 4 means all fitted
        for (int i=0; i< NUM_CHANNEL; i++) {
            hsi_precision[i] = (int)(is_double?msg.get(i).doubleValue():msg.get(i).floatValue());
            sum_precision += hsi_precision[i];
            if (hsi_precision[i] > 2)
                detection_start_time = -1;
        }

        if (state ==  FITTING && sum_precision == 4)
            changeState(DETECTION); // TODO: skipped CALIBRATION    s
    }
    else {
        debugPrint(" No horseshoe status\n");
    }
}

/* Absolute Band Power */
void getAbsolute(OscMessage msg) {
    boolean has_NaN = get_elements_data(msg, "absolute", absolute);

    if (!has_NaN && state == DETECTION)
        detect_calmness(msg);
}

/*Relative Band Power */
void getRelative(OscMessage msg) {
    get_elements_data(msg, "relative", relative);
}

boolean get_elements_data(OscMessage msg, String element_name, double[] data_array) {
    boolean has_NaN = false;
    // double[] result_data = new double[5];

    for (int i = 0; i < 5; i++) {
        if (msg.checkAddrPattern(muse_name + "/elements/" + BANDS[i] + "_" + element_name)) {
            double sum = 0;
            if (msg.checkTypetag("dddd")) {
                for (int j = 0; j < NUM_CHANNEL; j++) {
                    sum += msg.get(j).doubleValue();
                    debugPrint(String.valueOf(msg.get(j).doubleValue()));
                }
                debugPrint("  " + BANDS[i] + "=" + String.valueOf(sum) + "\n");
            }
            else if (msg.checkTypetag("ffff")) {
                for (int j = 0; j < NUM_CHANNEL; j++) {
                    sum += (double)msg.get(j).floatValue();
                }
            }
            else
                debugPrint("Type unknown");

            if (!Double.isNaN(sum))
                // result_data[i] = sum/4;
                data_array[i] = sum/4;
            else {
                has_NaN = true;
                debugPrint(" " + BANDS[i] + "  NaN");
            }
        }
    }
    return has_NaN;
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

/* Helper Methods */
int current_time() {
    return (hour() * 60 + minute()) * 60 + second();
}

/* Debug helper */
void debugPrint(String s) {
    if (debug) print(s);
}
