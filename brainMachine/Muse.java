import java.util.ArrayList;

class Muse {

    static ArrayList<Muse> list = new ArrayList<Muse>();
    static int counter;
    static Muse in_use;

    int id;
    String name;
    boolean using = false;

    // Data
    int[] hsi_precision = new int[4];
    boolean headband_on = false;

    Muse (String headband_name) {
        name = headband_name;
        id = list.size();
        list.add(this);
    }

    static public ArrayList<Muse> get_list() {
        return list;
    }

    static public int get_number() {
        return list.size();
    }

    static public void start_using(Muse muse) {
        for (Muse m : list) {
            m.using = false;
        }
        muse.using = true;
        in_use = muse;
    }

    static public Muse toggle() {
        for (Muse m : list) {
            m.using = !m.using;
            if (m.using)
                in_use = m;
        }
        return in_use;
    }

    // void update() {

    // }


}
