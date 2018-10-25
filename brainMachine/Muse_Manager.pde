/* Muse Headbands Manager by Linda Zhang */

/*  This is used to manage more than one Muse Headbands,
    as well as for communicating with the nodeJS server
    for the web app Muse Diagram that's used for visualization
 */
//////////////////////////////////////////////////////


// List of Muse Headband
Muse[] muse = new Muse[2]; // Enter the number of headbands

void muse_manager_setup() {
    muse[0] = new Muse("Muse_black"); // Connected via Muse Direct (Win 10)
    muse[1] = new Muse("/Muse"); 	  // Connected via Muse Monitor (iOS App)
    Muse.start_using(muse[0]);
}

void update_muse_manager() {
    for (int i = 0; i < muse.length; i++) {
        muse[i].update();
    }
}

void toggle_headbands() {
	Muse start_using = Muse.toggle();
    println("Switch to " + start_using.name);
	OscMessage myMessage = new OscMessage(start_using.name + "/toggle_on");
	myMessage.add(0);
	oscP5.send(myMessage, muse_manager_address);
}