/* Muse Headband Reader by Linda Zhang */

//////////////////////////////////////////////////////

final static boolean is_projecting = false;

// Debug
final static boolean debug = false;
final static boolean debugOSC = false;

// OSC data streamming
import oscP5.*;
import netP5.*;
final static String muse_name = "muse"; // "muse" default setting, "/muse" if via Muse Monitor app
final static int recvPort = 8980;
OscP5 oscP5;
// To communicate with nodeJS server (visualization)
final static NetAddress muse_manager_address = new NetAddress("127.0.0.1", 7980);

// Time
// import java.util.Calendar;
// import java.util.TimeZone;
// Calendar calendar;
// TODO use ISO time: System.currentTimeMillis()

// MACROS
final static boolean MEDITATION_MODE = true; // "true" for mediation, "false" for clam detection mode
final static int CALM_TIME = 5;   // How many consecutive seconds of calm time must be detected before entering A.I state
final static int MEDITATION_TIME = 60; // Length of the meditation time in seconds, default 60 seconds
final static int NUM_CHANNEL = 4;
final static int NUM_BAND = 5;
final static String[] BANDS = {"alpha", "beta", "gamma", "delta", "theta", "EEG"};
final static color[] COLORS = {#E0FFFF, #FF5733, #F4D03F, #B0A94F, #82E0AA, #000000};
final static int RECT_HEIGHT = 200;
final static int RECT_WIDTH = 50;
final static int BASELINE_HEIGHT = 500;
final static int DIAGRAM_LEFT_LIMIT = 40;

// Bands
final static int ALPHA = 0;
final static int BETA = 1;
final static int GAMMA = 2;
final static int DELTA = 3;
final static int THETA = 4;

// States
final static String[] STATES = {"IDLE", "FITTING", "CALIBRATION", "EXPLAINATION", "MEDITATION", "BCI", "DETECTION"};
final static int IDLE = 0;           // Headband not on
final static int FITTING = 1;        // Adjusting the headband until fitted
final static int CALIBRATION = 2;    // 20 seconds of calibration
final static int EXPLAINATION = 3;   // Guide user through 3 different interactions
final static int DETECTION = 6;      // Detecting 10 seconds of continuous 'calm'
final static int BCI = 5;            // Final state after "flipped"
final static int MEDITATION = 4;    // IF Meditation Mode

// Audio Cues
final static int[] number_of_clips = {1, 2, 2, 9, 2};
SoundFile[][] audio_cue = new SoundFile[5][];
SoundFile calibration_done;
SoundFile skip_step;
int curr_clip;  // The current clip playing
int audio_time = -1; // Time when audio is done; to keep track of when to play the next clip
boolean waiting_for_nod = false;

// Data
int[] hsi_precision = new int[4];
float[] absolute = new float[5];
float[] score = new float[5];
float[] eeg;
// float[] gyroscope = new float[3];
boolean[] good_connection = new boolean[4];
int is_good;
boolean headband_on = false;
boolean has_data = false;

// Calibration & Detection
float beta_upper_limit = 0.3; // Calculated by average of of Beta absolute band power during CALIBRATION state
float beta_sum;               // Sum of Beta absolute band power during CALIBRATION state
int calibration_data_points;  // The number of beta data points collected duirng CALIBRATION state
int beta_data_points;         // The number of beta data points collected duirng DETECTION / MEDITATION state
boolean start_meditation = false;
boolean nodded = false;
int gyro_state = 0;
int nod_counter;

// State Machine
int state = IDLE;
int curr_time;
int calm_start_time = -1;
int state_start_time = -1;
int calibration_time = -1;
int milliseconds_start;

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
    skip_step = new SoundFile (this, "AudioCues/SKIP.wav");

    for (int i = 0; i < number_of_clips.length; i++) {
        audio_cue[i] = new SoundFile[number_of_clips[i]];
        for (int j = 0; j < number_of_clips[i]; j++) {
            audio_cue[i][j] = new SoundFile(this, "AudioCues/" + STATES[i] + String.valueOf(j) + ".wav");
        }
    }

    curr_time = current_time();
    last_reset_time = curr_time;
}

void draw_Muse_Reader() {
    curr_time = current_time();
    fill(0);
    // println(state);

    // State Machine
    switch (state) {
        case 0: // IDLE
            if ((curr_time - state_start_time - 1) % 8 == 0)
                play_audio(curr_clip);

            if ((curr_time - state_start_time - 1) % 16 == 0) {
                resetBrain();
                state_start_time--;
            }
            break;
        case 1:
            if ((curr_time - state_start_time) > 2 && good_connection[1] && good_connection[2]) { // Sensors at the ears not fitted correctly
                state_start_time = curr_time - 8;
                play_audio(1);
                break;
            }

            if ((curr_time - state_start_time) % 10 == 0) {
                state_start_time = curr_time - 1;
                play_audio(0);
            }
            break;

        case 2: // CALIBRATION
            calibration_time =  curr_time - state_start_time;
            if (calibration_data_points >= 70)
                change_state_when_finished();
            // changeState(EXPLAINATION); //TODO testing only, skip calibration
            // TODO missing second audio
            break;

        case 3: // EXPLAINATION
            if (curr_clip == 0 || waiting_for_nod) {
                if (detect_nod()) {
                    waiting_for_nod = false;
                    nextClip();
                    if (curr_clip + 1 >= number_of_clips[state]) changeState(MEDITATION);
                }
                break;
            }

            // Do nothing if the audio is still playing
            if (audio_cue[state][curr_clip].isPlaying()) break;
            // If audio stopped:
            switch (curr_clip % 3) { //<>//
                case 0:
                    if (curr_clip == 0)
                        nextClip();
                    else // clip = 3, 6
                        wait_nod();
                    break;
                case 1:  // clip = 1, 4 or 7
                    if (audio_time < 0)
                        audio_time = curr_time;
                    else if (audio_time > 0 && curr_time - audio_time > 3)    // wait for 3 seconds and play next clip
                        nextClip();
                    break;
                case 2:  // clip = 2, 5, or 8
                    if (curr_clip == 8) {
                        wait_nod();
                        break;
                    }

                    if (audio_time < 0)
                        audio_time = curr_time;
                    else if (audio_time > 0 && curr_time - audio_time > 5)    // wait for 5 seconds and play next clip
                        nextClip();
                    break;
            }
            break;

        case 4: // MEDITATION
            if (curr_time - state_start_time > MEDITATION_TIME) {
                changeState(BCI); // TODO MEDITATION_END
                break;
            }

            if (!start_meditation && audio_cue[state][curr_clip].isPlaying()) {
                state_start_time = curr_time;        // reset state start time
                start_meditation = true;             // meditation starts
                milliseconds_start = millis();
            }
        default:
            break;
    }
    // println(audio_time, waiting_for_nod);

    if ((curr_time - state_start_time) % 5 == 0)
        randomly_moving = false;

    // Testing
    text("State:", 800, 15);
    text(STATES[state], 850, 15);
    text(curr_clip, 950, 15);

    if (calm_start_time > 0) text(curr_time - calm_start_time, 900,40);
    else text(curr_time - state_start_time, 900,40);
    text(beta_upper_limit, 900,25);

    text(calibration_data_points, 930, 40);
    text("#data " + beta_data_points, 900, 55);

    for (int i = 0; i < 4; i++)
        text((good_connection[i]?"good":"bad"), 10, 10 + i * 15);

    // Draw bar chart
    if (state == BCI) {
        visualizeData(score);
    }
    else
        visualizeData(absolute);
        // visualizeData(gyroscope);
}

void keyReleased() {
    if (key == ENTER)
        // changeState(state + 1);
       changeState(state+1==STATES.length?0:state+1);
    else if (key == ' ') {
        good_connection[1] = !good_connection[1];
        good_connection[2] = !good_connection[2];
    }
    else if (key == 's' && state == EXPLAINATION) {    // Skip the "tutorial", to meditation state
        // curr_clip += 3;
        // if (curr_clip > number_of_clips[EXPLAINATION])
        changeState(MEDITATION);
    }
}

boolean detect_nod() {
    if (keyPressed && key == 'n') // manually press 'N' on keyboard to continue
        return true;

    if (nodded) {
        nodded = false;
        return true;
    }
    return false;
}

void wait_nod() {
    if (audio_time < 0)
        audio_time = curr_time;
    else if (audio_time > 0 && curr_time - audio_time > 3) {
        skip_step.play();
        waiting_for_nod = true;
    }
}

void resetBrain() { // DEBUG
    idleChange = true;
    last_reset_time = curr_time;
    idleReset();
}

void changeState(int new_state) {
    OSC_send_state(new_state); // Inform muse manager about new state

    // Old State
    if (state == CALIBRATION) {
        calibration_done.play();
        // Calculate average beta band from calibration
        beta_upper_limit = beta_sum / calibration_data_points;
        if (Float.isNaN(beta_upper_limit)) // || beta_upper_limit < 0.1
            beta_upper_limit = 0.1;
        println("Beta Upper Limit = ", beta_upper_limit);

        // For visualizing meditation result
        diagram_bottom_y = BASELINE_HEIGHT + beta_upper_limit * RECT_HEIGHT * 2;
        println ("rect y = ", diagram_bottom_y);

        // Send beta_upper_limit to BrainDiagram as a baseline of the diagram
        OscMessage baseline_msg = new OscMessage("Person0/baseline");
        baseline_msg.add(beta_upper_limit);
        OSC_send(baseline_msg);
    }
    else if (state == BCI) {  // reset collected data
        beta_upper_limit = 0.3;
        calibration_data_points = 0;
        // beta = new float[1000];
        // good = new int[1000];
    }

    // Stop previous audio
    println(state, curr_clip);
    if (state < number_of_clips.length && curr_clip < number_of_clips[state])
        audio_cue[state][curr_clip].stop();

    println("Change to new state: ", STATES[new_state]);
    state = new_state;
    state_start_time = curr_time;
    curr_clip = 0;
    nodded = false;

    if (new_state == IDLE) {
        // audio_cue[state][0].play();
        resetBrain();
        artBrainLoop.stop();
        humBrainLoop.stop();
        rectY = 200;
    }
    else if (new_state == CALIBRATION) {
        audio_cue[state][0].play();
        humBrainLoop.loop(1);
    }
    else if (new_state == EXPLAINATION) {
        audio_cue[state][0].play();
        resetBrain();
    }
    else if (new_state == MEDITATION)
        audio_cue[state][0].play();
    else if (new_state == BCI) {
        humBrainLoop.stop();
        artBrainLoop.loop(1);
        rectY = 50;
    }
}

void nextClip() {
    if (curr_clip + 1 < number_of_clips[state]) {
        audio_cue[state][curr_clip].stop(); // Stop the current clip
        audio_cue[state][curr_clip + 1].play();
    }
    curr_clip++;
    audio_time = -1;
}

void play_audio(int clip_to_play) {
    if (!audio_cue[state][curr_clip].isPlaying()) {
        curr_clip = clip_to_play;
        audio_cue[state][curr_clip].play();
    }
}

/* Change to next state whenever the current audio clip has finished playing */
void change_state_when_finished() {
    if (!audio_cue[state][curr_clip].isPlaying())
        changeState(state + 1);
}

void oscEvent(OscMessage msg) {
    if (debugOSC) {
        print("---OSC Message---");
        println(msg);
    }

    randomly_moving = true;
    getHeadbandStatus(msg);

        getGyroscope(msg);
    if (state > FITTING && state < BCI) {
        getAbsolute(msg);
    }

    if (state > CALIBRATION)
        getScore(msg);
}

void collect_meditation(boolean has_beta_data) {
    if (!start_meditation) //  && beta_data_points >= beta.length Data array overflow
        return;
    int timestamp = (millis() - milliseconds_start) / 100; // Precision set to 0.1 seconds
    // Get rid of duplicate data
    // if (eeg[BETA] == prev_eeg)
    //     return;

    OscMessage data_msg = new OscMessage("Person0/data/beta");
    data_msg.add(absolute[BETA]);
    data_msg.add(timestamp);
    data_msg.add(is_good);
    OSC_send(data_msg);

    data_msg = new OscMessage("Person0/data/alpha");
    data_msg.add(absolute[ALPHA]);
    data_msg.add(timestamp);
    data_msg.add(is_good);
    OSC_send(data_msg);
}

/* Visualization Bar Chart */
void visualizeData(float[] data_array) {
    for (int i = 0; i < data_array.length; i++) {
        rect_x = 550 + i * 100;
        // Draw bars
        if (!is_projecting) {
            fill(COLORS[i]);
            rect_height = (int)((data_array[i] * RECT_HEIGHT));
            rect(rect_x, 700 - rect_height / 2, RECT_WIDTH, rect_height);
        }
        // Display band names and data
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
    // OSC_send(msg);

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

    // Strict data quality indicator for each channel, 0 = bad, 1 = good
    if (state > IDLE && msg.checkAddrPattern(muse_name + "/elements/is_good"))
    {
        is_good = 0;
        for (int i=0; i< NUM_CHANNEL; i++) {
            good_connection[i] = get_OSC_value(msg, i) == 1;
            if (get_OSC_value(msg, i) == 1)
                is_good++;
        }

        if (state ==  FITTING && is_good == 4) // 4 means all fitted
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
        else if (calibration_data_points < 70 && state == CALIBRATION && calibration_time > 12 && is_good > 2)
        {
            beta_sum += absolute[BETA];
            calibration_data_points++;

            if (calibration_time > 20 && calibration_data_points > 70) {
                // changeState(EXPLAINATION);
                curr_clip++;
            }
        }
    }
}

/* Band Power Score */
void getScore(OscMessage msg) {
    get_elements_data(msg, "session_score", score);
}

int gyro_threshold = 40; // How much do you need to move in order to trigger a "nod"
/* Gyroscope data */
void getGyroscope(OscMessage msg) {
    if (msg.checkAddrPattern(muse_name + "/gyro")) {
        // println(msg);
        // for (int i = 0; i < 3; i++) {
        //     if (msg.checkTypetag("fff"))
        //         gyroscope[i] = msg.get(i).floatValue();
        // }
        float y = msg.get(1).floatValue();

        switch (gyro_state) {
            case 1: // Head up
                if (y < 0) {
                    gyro_state = 0;
                    nodded = true;
                    nod_counter = curr_time;
                    println("Nodded~~~~~~");
                }
                break;
            case -1: // Head down
                if (y > gyro_threshold) {
                    gyro_state = 1;
                }
                break;
            case 0:
            default :
                if (y < -1 * gyro_threshold) {
                    gyro_state = -1;
                }
                if (nod_counter > 0 && curr_time - nod_counter > 2) {
                    nodded = false;
                    nod_counter = 0;
                }
            break;
        }
    }
}

/* Get OSC data within the "elements" category */
boolean get_elements_data(OscMessage msg, String element_name, float[] data_array) {
    if (is_good < 2) // Bad connection
        return false;

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


void OSC_send_state(int state) {
  /* in the following different ways of creating osc messages are shown by example */
  OscMessage myMessage = new OscMessage("Person0/state");
  myMessage.add(state); /* add an int to the osc message */
  /* send the message */
  oscP5.send(myMessage, muse_manager_address);
}

void OSC_send(OscMessage msg) {
  oscP5.send(msg, muse_manager_address);
}


/* Debug helper */
void debugPrint(String s) {
    if (debug) print(s);
}


