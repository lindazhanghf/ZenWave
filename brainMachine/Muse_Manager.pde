/* Muse Headbands Manager by Linda Zhang */

/*  This is used to manage more than one Muse Headbands,
    as well as for communicating with the nodeJS server
    for the web app Muse Diagram that's used for visualization
 */
//////////////////////////////////////////////////////

void muse_manager_setup() {
    // Take the first muse as the default:
    Muse default_headband =
    // new Muse("Muse_black"); // Connected via Muse Direct (Win 10); "Muse_white"
    new Muse("/muse"); 	   // Connected via Muse Monitor (iOS App)
    // new Muse("Person0");       // Default setting of Muse Direct
    // new Muse("Muse_white");
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
    if (state > FITTING && state < BCI) {
        getAbsolute(msg, Muse.in_use.name);
    }

    // if (state > FITTING)
    //     getScore(msg, Muse.in_use.name);
}

void toggle_headbands() {
	Muse start_using = Muse.toggle();
    println("Switch to " + start_using.name);
	OscMessage myMessage = new OscMessage(start_using.name + "/toggle_on");
	myMessage.add(0);
	oscP5.send(myMessage, muse_manager_address);
    changeState(IDLE);
}