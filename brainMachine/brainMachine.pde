/* Brain Poster by Pedro Arevalo */

//////////////////////////////////////////////////////

// Sound Library
import processing.sound.*;

// need to import this so we can use Mixer and Mixer.Info objects
import javax.sound.sampled.*;

import java.util.Map;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ConcurrentHashMap;

import codeanticode.syphon.*;
SyphonServer server;

// Leap Motion Variables
int currentState = 1;
boolean wait = false;

// Project Variables
boolean rightHandCheck; // Check if hand is right or left
float handSphereRadius;
int fingers = 0;        // Number of Fingers being displayed
float strength;         // Grabbing strength
float rectY;
float[] colors = new float[5];

// Gesture triggers
Boolean changeGesture = false;
Boolean fingerChange = false;
float checkGesture = 0;
int currentFinger;
int lastFinger;

// Sketch Width and Height
int appWidth = 1000;
int appHeight = 1000;


//////////////////////////////////////////////////////

Neuron n[];
Signal s[];

boolean render = false;

// Image Variables
PImage brainCore;

// Audio File
SoundFile artBrainLoop;
SoundFile humBrainLoop;

//////////////////////////////////////////////////////

void settings() {
  size(1000,1000, P2D);
  PJOGL.profile=1;
}

void setup() {
  //Syphon Server Setup (for projection)
  server = new SyphonServer(this, "Processing Syphon");
  // size(1000,900,P2D);

// Images Setup
  brainCore = loadImage("brainMask.png");

// Audio Loop
  artBrainLoop = new SoundFile (this, "artBrain.mp3");
  humBrainLoop = new SoundFile (this, "jazzLoop.wav");
  // humBrainLoop.loop(1);

  // Neuron Setup
  n = new Neuron[580];

  for(int i = 0;i<n.length;i++) { // Sections of Brain

// This is the are where the networks will be created at start!
    if (i <= 180){
      n[i] = new Neuron(i, random(500, 950), random(125, 560));
    }

    else if (i > 180 && i <= 280) {
      n[i] = new Neuron(i, random(164, 510), random(120, 420));     }

    else if (i > 280 && i <= 380) {
      n[i] = new Neuron(i, random(88, 320), random(290, 550));
    }

    else if (i > 380 && i <= 480) {
      n[i] = new Neuron(i, random(140,495), random(560,820));

    } else if (i > 480) {
      n[i] = new Neuron(i, random(302, 680), random(390, 646));
    }

  }

  for(int i = 0;i<n.length;i++) {
    n[i].makeSynapse();
  }

  rectMode(CENTER);

  for(int i = 0;i<n[0].s.length;i++) {
    n[0].makeSignal(i);
  }

  // Testing
  rectY = 200;
  fingers = 5;

  setup_Muse_Reader();
}


////////////////////////////////////////////////////////

void draw() {
  // Background
  if(is_human_brain()) {
    background(4, 71, 88, 11);
  } else if (!is_human_brain()) {
    background(255, 11);
  }

  // if (state == BCI)
  //   // artBrainLoop.rate(abs(rectY / 1080) - 1.5);
  //   // artBrainLoop.rate(absolute[ALPHA] + 0.5);
  //   artBrainLoop.rate(1);
  // else
  if (state > CALIBRATION) {
    // float rate = abs(1-absolute[BETA] - 1.8);
    float rate = abs(absolute[BETA] + 1 - beta_upper_limit);
    humBrainLoop.rate(rate);
  }


  pushMatrix();
  scale(1);

  for(int i = 0;i<n.length;i++) {
    n[i].drawNeuron();
  }

  popMatrix();

  resetNeurons();

  image(brainCore,0,0,1000,1000);


  ////////////////////////////////////////////////////////

  server.sendScreen(); // Sending screen to SythonServer
  draw_Muse_Reader();
}

// Helper Function
boolean is_human_brain()
{
  if (currentState % 2 != 0)
    return true;
  // else
  return false;
}

int find_brain_sections(float x, float y)
{
  // BRAIN SECTION 3
  if (x > 635 || x > 500 && y < 405)
    return 3;
  // BRAIN SECTION 2
  else if ((x > 250 && x <= 500 && y < 420) || (x > 10 && x <= 260 && y < 322))
    return 2;
  // BRAIN SECTION 1
  else if ((x > 10 && x < 260 && y > 270 && y < 570) || (x > 240 && x < 330 && y < 560))
    return 1;
  // BRAIN SECTION 0
  else if (x > 90 && x < 500 && y > 560)
    return 0;

  // else BRAIN SECTION 4
  return 4;
}

////////////////////////////////////////////////////////

class  Neuron {
  int id;
  float x,y,val,xx,yy;
  float radius = 60.0;

  Synapse s[];
  Signal sig[];

  Neuron(int _id,float _x,float _y){
    val = random(255);
    id=_id;
    xx = x=_x;
    yy = y=_y;
  }

  void makeSynapse() {

    s = new Synapse[0];
    sig = new Signal[0];

    for(int i = 0;i<n.length;i++) {
      if(i!=id && dist(x,y,n[i].x,n[i].y) <= radius && noise(i/100.0) < 0.8) {
        s = (Synapse[])expand(s,s.length+1);
        s[s.length-1] = new Synapse(id,i);

        sig = (Signal[])expand(sig,sig.length+1);
        sig[sig.length-1] = new Signal(s[s.length-1]);

      }
    }
  }



  void makeSignal(int which) {
    int i = which;
    sig[i].x = xx;
    sig[i].y = yy;
    sig[i].running = true;
  }




  void

  drawSynapse() {
    int band = BETA; // Only visualize the Beta band
    switch (find_brain_sections(x, y)) {
      case 3:
        // band = ALPHA;
        if (hsi_precision[3] > 0 && hsi_precision[3] < 4)
          stroke(0 + (24 * 2), 255 + (24 * 2), 180 - (24 * 2), score[band] * 80 + 20);
        else
          stroke(150, score[band] * 80 + 20);
        break;
      case 2:
        // band = BETA;
        if (hsi_precision[2] > 0 && hsi_precision[2] < 4)
          stroke(242, 242 - (24 / 2), 13 + 24, score[band] * 80 + 20);
        else
          stroke(150, score[band] * 80 + 20);
        break;
      case 1:
        // band = GAMMA;
        if (hsi_precision[1] > 0 && hsi_precision[1] < 4)
          stroke(255 , 159 - (125 / 3), 102 - 125, score[band] * 80 + 20);
        else
          stroke(150, score[band] * 80 + 20);
        break;
      case 0:
        // band = DELTA;
        if (hsi_precision[0] > 0 && hsi_precision[0] < 4)
          stroke(255,51,51 + (125 * 1.5),score[band] * 80 + 20);
        else
          stroke(150, score[band] * 80 + 20);
        break;
      default : // case 4
        // band = THETA;
        if (headband_on)
          stroke(255, 128 - (125 / 2),0,score[band] * 80 + 20);
        else
          stroke(150, score[band] * 80 + 20);
      break;
    }
    if (!is_human_brain())
      fill_in_synapse_AI();

    for(int i = 0;i<s.length;i+=1) {
      line(n[s[i].B].xx,n[s[i].B].yy,xx,yy);
    }

  }

  void drawSignal () {

    if(sig.length > 0) {
      for(int i = 0; i < sig.length; i++) {
        if(sig[i].running) {
          try {
            pushStyle();
            // print("_"); //debug

            if(is_human_brain()) {
              strokeWeight(1); // Size of Synapse
              stroke(255, 153, 51, 70); // Color of synape
            } else {
              strokeWeight(1.5); // Size of Synapse
              stroke(255, 0, 102, 80); // Color of synape
            }

            noFill();
            // print(sig[i].x, "|", sig[i].lx); //debug
            line(sig[i].x, sig[i].y, sig[i].lx, sig[i].ly);
            popStyle();
            sig[i].step();
            // print("✓ "); //debug
          } catch (ArrayIndexOutOfBoundsException e) {
            print("BREAKS!", sig.length, " signals ");  //debug
            println(" ", i); //debug
          }
        }
      }
    }
  }

  void drawNeuron () {

    if (!idleChange) {
      if (state > IDLE)
        drawSignal();

      drawSynapse();
    }


    xx += (x-xx) / 8.0; // Speed of re-organization of neurons
    yy += (y-yy) / 8.0; // Speed of re-organization of neurons

    // if (state < DETECTION)
    if (randomly_moving && state < FITTING)
      randomMovement(); // Uncomment this to enable movement of neural networks
  }

  void randomMovement() {
//    x+=(noise(id+BframeCount/10.0)-0.5);
//    y+=(noise(id*5+frameCount/10.0)-0.5);
    x+=(random(-0.4,0.4));
    y+=(random(-0.4,0.4));
  }

  /* Coloring function */

  // Fill in the default color of the synapse
  void fill_in_synapse_default() {
    if(is_human_brain()){
      stroke(77, 142, 159, 45);
    } else {
      stroke(0, 51, 153, 45);
    }
  }

  void fill_in_synapse_AI() {
    int col = (int)(abs((score[ALPHA] * 50) + 12)) * 2;
    stroke(0 + col, 255 - col, 0 + (col * 3), 45);
  }

}


///////////////////////////////////////////////////////

class Synapse {

  float weight = 1.5;
  int A,B;

  Synapse(int _A, int _B){

    A=_A;
    B=_B;

    weight = random(101,1100)/300.9; // Speed of expanding to other neurons
  }

}

//////////////////////////////////////////////////////////

class Signal {

  Synapse base;
  int cyc = 0;
  float x,y,lx,ly;
  float speed = 10.1; // Speed of dots when re-organizing

  boolean running = false;
  boolean visible = true;

  int deadnum = 200;
  int deadcount = 0;

  Signal(Synapse _base) {
    deadnum = (int)random(2,400);
    base = _base;
    lx = x = n[base.A].x;
    ly = y = n[base.A].y;
    speed *= base.weight;
  }

  void step() {
    running = true;

    lx = x;
    ly = y;

    x += (n[base.B].xx-x) / speed; //(speed+(dist(n[base.A].x,n[base.A].y,n[base.B].x,n[base.B].y)+1)/100.0);
    y += (n[base.B].yy-y) / speed; //(speed+(dist(n[base.A].x,n[base.A].y,n[base.B].x,n[base.B].y)+1)/100.0);

    // println(y);

    if(dist(x,y,n[base.B].x,n[base.B].y)<1.0){

      if(deadcount < 0) {
        deadcount = deadnum;

        for(int i = 0;i<10;i++) { // To add blur in explosion

          pushStyle(); // EXPLOSION COLOR PARAMETERS
          noFill();
          noStroke();

          if (fingers >= 5) {
            fill_in_explosion();
          }

//////////////// END OF PARAMETERS

          // Position & Size of explosion
          // ellipse(x, y, (abs((rectY / 300) - 4)) * i, (abs((rectY / 300) - 4)) * i);
          ellipse(x, y, (abs((absolute[BETA] + 0.3 - beta_upper_limit) * 6)) * i, (abs((absolute[BETA] + 0.3 - beta_upper_limit) * 6)) * i);
          popStyle();
        }

        // deadnum += (int)random(-1,1);
        // println("run "+base.A+" : "+base.B);

        running = false;
        for(int i = 0; i < n[base.B].s.length;i++) {
          if(!n[base.B].sig[i].running && base.A!=n[base.B].sig[i].base.B){
            n[base.B].makeSignal(i);
            n[base.B].sig[i].base.weight += (base.weight-n[base.B].sig[i].base.weight)/((dist(x,y,n[base.A].xx,n[base.A].yy)+1.0)/200.0);
          }
        }

        //base.weight = random(1001,3000) / 1000.0;

        n[base.A].xx+=((n[base.B].x-n[base.A].x)/1.1)*noise((frameCount+n[base.A].id)/11.0);;
        n[base.A].yy+=((n[base.B].y-n[base.A].y)/1.1)*noise((frameCount+n[base.A].id)/10.0);

        n[base.A].xx-=((n[base.B].x-n[base.A].x)/1.1)*noise((frameCount+n[base.B].id)/10.0);;
        n[base.A].yy-=((n[base.B].y-n[base.A].y)/1.1)*noise((frameCount+n[base.B].id)/11.0);

        lx = n[base.A].xx;
        ly = n[base.A].yy;

        n[base.A].val+=(n[base.B].val-n[base.A].val)/5.0;

      } else {

        deadcount--;
      }
    }
  }

  // Helper function
  void fill_in_explosion()
  {
    if(is_human_brain()){
      fill(255,20);
    } else {
      fill(0, 102, 204, 20);
    }
  }
}

