/* Muse Headbands Manager by Linda Zhang */

/*  This is used to manage more than one Muse Headbands,
    as well as for communicating with the nodeJS server
    for the web app Muse Diagram that's used for visualization
 */
//////////////////////////////////////////////////////

// Debug
final static boolean debug = false;
final static boolean debugOSC = false;

void muse_manager_setup() {
    // Take the first muse as the default:
    Muse default_headband =
    new Muse("Muse_black");    // Connected via Muse Direct (Win 10)
    new Muse("/muse"); 	       // Default setting of Muse Monitor app
    // new Muse("Person0");       // Default setting of Muse Direct (Win 10)
    // new Muse("Muse_white");    // Connected via Muse Direct (Win 10)
    Muse.start_using(default_headband);
}

void oscEvent(OscMessage msg) {
    if (debugOSC) {
        print("---OSC Message---");
        println(msg);
    }

    randomly_moving = true;
    for (Muse m : Muse.get_list()) {
        getHeadbandStatus(msg, m);
    }

    getGyroscope(msg, Muse.in_use.name);
    if (Muse.in_use.state > FITTING) {
        getAbsolute(msg, Muse.in_use.name);
    }
}

void toggle_headbands() {
    // Stop previous audio cue
    if (Muse.in_use.state < number_of_clips.length && curr_clip < number_of_clips[Muse.in_use.state])
        audio_cue[Muse.in_use.state][curr_clip].stop();

	Muse start_using = Muse.toggle();
    println("Switch to " + start_using.name);
	OscMessage myMessage = new OscMessage(start_using.name + "/toggle_on");
	myMessage.add(0);
	oscP5.send(myMessage, muse_diagram_address);
    changeState(IDLE);
}


void change_state(Muse m, int new_state) {
    m.state = new_state;
    OscMessage myMessage = new OscMessage(m.name + "/state");
    myMessage.add(m.state);
    oscP5.send(myMessage, muse_diagram_address);
}
