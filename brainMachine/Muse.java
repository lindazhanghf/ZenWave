import java.util.ArrayList;

class Muse {

    static ArrayList<Muse> list = new ArrayList<Muse>();
    static int counter;

    int id;
    String name;
    boolean in_use = false;

    // Data
    int[] hsi_precision = new int[4];
    boolean headband_on = false;

    Muse (String headband_name) {
        name = headband_name;
        id = list.size();
        list.add(this);
    }

    static public int getNumOfMuses() {
        return list.size();
    }

    static public void start_using(Muse muse) {
        for (Muse m : list) {
            m.in_use = false;
        }
        muse.in_use = true;
    }

    void update() {

    }


}
