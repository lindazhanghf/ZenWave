/* Muse Headbands Manager by Linda Zhang */

/*  This is used to manage more than one Muse Headbands,
    as well as for communicating with the nodeJS server
    for the web app Muse Diagram that's used for visualization
 */
//////////////////////////////////////////////////////


// List of Muse Headband
Muse[] muse = new Muse[2]; // Enter the number of headbands

void muse_manager_setup() {
    muse[0] = new Muse("Person0");
    muse[1] = new Muse("Person1");
}

void update_muse_manager() {
    for (int i = 0; i < muse.length; i++) {
        muse[i].update();
    }
}

void parse_OSC_message(OscMessage msg) {

}