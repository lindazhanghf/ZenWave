/* Brain Poster by Pedro Arevalo */

//////////////////////////////////////////////////////

// Sound Library
import processing.sound.*;

// need to import this so we can use Mixer and Mixer.Info objects
import javax.sound.sampled.*;

import java.util.Map;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ConcurrentHashMap;

// import com.leapmotion.leap.Controller;
// import com.leapmotion.leap.Finger;
// import com.leapmotion.leap.Frame;
// import com.leapmotion.leap.Gesture;
// import com.leapmotion.leap.Hand;
// import com.leapmotion.leap.Tool;
// import com.leapmotion.leap.Vector;
// import com.leapmotion.leap.processing.LeapMotion;

// // Palm tracking
// import com.leapmotion.leap.Pointable;
// import com.leapmotion.leap.InteractionBox;
// import com.leapmotion.leap.HandList;

// LeapMotion leapMotion;

// Vector palmPosition;
// Vector filteredHandPosition; // Mapping

// Ex Vector
// Vector leapPoint;
// Vector normalizedPoint;

// Leap Motion
int currentState = 1;
boolean wait = false;

// Project Variables
boolean rightHandCheck; // Check if hand is right or left
float handSphereRadius;
int fingers = 0; // Number of Fingers being displayed
float strength; // Grabbing strength
float rectX;
float rectY;
float rectZ;
float xColor;
float yIntensity;

// Gesture triggers
Boolean changeGesture = false;
Boolean fingerChange = false;
float checkGesture = 0;
int currentFinger;
int lastFinger;

// Sound Variables
float adjustAi = 0;


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

void setup() {

  size(1000,1000,P2D);

// Images Setup
  brainCore = loadImage("brainMask.png");

// Audio Loop
  // artBrainLoop = new SoundFile (this, "artBrain.mp3");
  humBrainLoop = new SoundFile (this, "humBrainPlay.mp3");
  humBrainLoop.loop(1);


  // Setup all vectors
  // leapMotion = new LeapMotion(this);
  // palmPosition = new Vector();
  // filteredHandPosition = new Vector();
  // handSphereRadius = 20;
  // leapPoint = new Vector();
  // normalizedPoint = new Vector();

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

}


////////////////////////////////////////////////////////

void draw() {

  // Background
  if(currentState % 2 != 0) {
    background(4, 71, 88, 11);
  } else if (currentState % 2 == 0) {
    background(255, 11);
  }

  // float appX = normalizedPoint.getX() * appWidth; // Increased palm position X
  // float appY = (1 - normalizedPoint.getY()) * appHeight; // Increased palm position Y
  // float appZ = (1 - normalizedPoint.getZ()); // Increased palm position Z

  // rectX = appX;
  // rectY = appY;
  // rectZ = appZ;
  rectX = 0;
  rectY = 50;
  rectZ = 0;

  // // Music Rate
  // if(abs((rectY / 1080) - 1.50) > 1.51) {
  //   adjustAi = 0.2;
  // } else {
  //   adjustAi = 0;
  // }

  // artBrainLoop.rate(abs((rectY / 1080) - 1.50) + adjustAi);
  // humBrainLoop.rate(abs((rectY / 1080) - 1.50));

  // Color Changer
  xColor = (abs((rectX / 20) + 12)) * 2;
  yIntensity = abs((((rectY + 20) / 3) - 425) / 2);

  pushMatrix();

  scale(1);

  for(int i = 0;i<n.length;i++) {
    n[i].drawNeuron();
  }

  popMatrix();

  resetNeurons();

  image(brainCore,0,0,1000,1000);


  ////////////////////////////////////////////////////////


 checkGesture += 0.5;

 if (checkGesture % 0.5 == 0 && changeGesture == true || checkGesture % 1 == 0 && idleChange == true){
   changeGesture = false;
   idleChange = false;
 } else if(wait == true && checkGesture % 41 == 0) {
   wait = false;
 } else if(checkGesture % 691 == 0 && fingers < 1 && strength <= 0) {
   idleChange = true;
 }

 idleReset();



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




  void drawSynapse() {

    if(sig.length > 0) {
      for(int i = 0; i < sig.length; i+= 1) {
        if(sig[i].running) {
          pushStyle();


          if(currentState % 2 != 0) {
            strokeWeight(1); // Size of Synapse
          } else if(currentState % 2 == 0){
            strokeWeight(1.5); // Size of Synapse
          }

          if(currentState % 2 != 0) {
            stroke(255, 153, 51, 70); // Color of synape
          } else if(currentState % 2 == 0){
            stroke(255, 0, 102, 80); // Color of synape
          }

          noFill();
          line(sig[i].x, sig[i].y, sig[i].lx, sig[i].ly);
          popStyle();
          sig[i].step();
        }
      }
    }


    if(x > 635 || x > 500 && y < 405 ) { // BRAIN SECTION 3
      if(fingers == 0 && strength > 0.5 || fingers == 5) {

//        stroke(lerpColor(#ff9966,#ff9933,norm(val,0,255)),20); // Color of the neural networks

          if(currentState % 2 != 0) {
            stroke(242, 242 - (xColor / 2), 13 + xColor, 45);
          } else if(currentState % 2 == 0){
            stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
          }



      } else {

        if(currentState % 2 != 0){
          stroke(77, 142, 159, 45);
        } else if(currentState % 2 == 0){
          stroke(0, 51, 153, 45);
        }

      }

    } else if(x > 250 && x <= 500 && y < 420) { // BRAIN SECTION 2
      if(fingers == 1 || fingers == 5) {
//        stroke(lerpColor(#ffff99,#ffff66,norm(val,0,255)),20);
       if(currentState % 2 != 0){
//          stroke(255 - (xColor * 1.2), 255, 128 - (xColor/ 1.5), 20);
          stroke(0 + (xColor * 2), 255 + (xColor * 2), 180 - (xColor * 2), 20);
        } else if(currentState % 2 == 0){
          stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
        }

      } else {

        if(currentState % 2 != 0){
          stroke(77, 142, 159, 45);
        } else if(currentState % 2 == 0){
          stroke(0, 51, 153, 45);
        }

      }

    } else if(x > 10 && x <= 260 && y < 322) { // BRAIN SECTION 2
      if(fingers == 1 || fingers == 5) {
//        stroke(lerpColor(#ffff99,#ffff66,norm(val,0,255)),20);

        if(currentState % 2 != 0){
          stroke(0 + (xColor * 2), 255 + (xColor * 2), 120 - (xColor/ 1.5), 20);
//          stroke(255 - (xColor * 1.2), 255, 128 - (xColor/ 1.5), 20);
        } else if(currentState % 2 == 0){
          stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
        }

      } else {

         if(currentState % 2 != 0){
            stroke(77, 142, 159, 45);
          } else if(currentState % 2 == 0){
            stroke(0, 51, 153, 45);
          }

      }

    } else if(x > 10 && x < 260 && y > 270 && y < 570) { // BRAIN SECTION 1
      if(fingers == 2 || fingers == 5) {

        if(currentState % 2 != 0){
          stroke(255 , 159 - (xColor / 3), 102 - xColor, 20);
        } else if(currentState % 2 == 0){
          stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
        }

      } else {

        if(currentState % 2 != 0){
          stroke(77, 142, 159, 45);
        } else if(currentState % 2 == 0){
          stroke(0, 51, 153, 45);
        }

      }

    } else if(x > 240 && x < 330 && y < 560) { // BRAIN SECTION 1
      if(fingers == 2 || fingers == 5) {

        if(currentState % 2 != 0){
          stroke(255 , 159 - (xColor / 3), 102 - xColor, 20);
        } else if(currentState % 2 == 0){
          stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
        }


      } else {

        if(currentState % 2 != 0){
          stroke(77, 142, 159, 45);
        } else if(currentState % 2 == 0){
          stroke(0, 51, 153, 45);
        }

      }

    } else if(x > 90 && x < 500 && y > 560) { // BRAIN SECTION 0
      if(fingers == 3 || fingers == 5) {

//        stroke(lerpColor(#0066ff,#0000ff,norm(val,0,255)),20);

        if(currentState % 2 != 0){
          stroke(255,51,51 + (xColor * 1.5),30);
        } else if(currentState % 2 == 0){
          stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
        }

      } else {

        if(currentState % 2 != 0){
          stroke(77, 142, 159, 45);
        } else if(currentState % 2 == 0){
          stroke(0, 51, 153, 45);
        }

      }

    } else {
      if(fingers == 4 || fingers == 5) {  // BRAIN SECTION 4

//        stroke(lerpColor(#cc33ff,#9933ff,norm(val,0,255)),20);
        if(currentState % 2 != 0){
          stroke(255, 128 - (xColor / 2),0,30);
        } else if(currentState % 2 == 0){
          stroke(0 + xColor, 255 - xColor, 0 + (xColor * 3), 45);
        }

      } else {

        if(currentState % 2 != 0){
          stroke(77, 142, 159, 45);
        } else if(currentState % 2 == 0){
          stroke(0, 51, 153, 45);
        }

      }

    }


    for(int i = 0;i<s.length;i+=1) {
      line(n[s[i].B].xx,n[s[i].B].yy,xx,yy);
    }

  }

  void drawNeuron () {
    drawSynapse();
    xx += (x-xx) / 8.0; // Speed of re-organization of neurons
    yy += (y-yy) / 8.0; // Speed of re-organization of neurons
    move(); // Uncomment this to enable movement of neural networks
  }

  void move() {
//    x+=(noise(id+frameCount/10.0)-0.5);
//    y+=(noise(id*5+frameCount/10.0)-0.5);
    x+=(random(-0.4,0.4));
    y+=(random(-0.4,0.4));
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


    if(dist(x,y,n[base.B].x,n[base.B].y)<1.0){

      if(deadcount < 0) {
        deadcount = deadnum;

        for(int i = 0;i<10;i++) {

          pushStyle(); // EXPLOSION COLOR PARAMETERS

          if(fingers == 0) {
            if(x > 635 || x > 500 && y < 405) {
              if(currentState % 2 != 0){
                fill(255,20);
              } else if(currentState % 2 == 0){
                fill(0, 102, 204, 20);
              }
            } else {
              noFill();
              noStroke();
            }
          } if(fingers == 1) {
            if(x > 250 && x <= 500 && y < 420 || x > 10 && x <= 260 && y < 322) {
              if(currentState % 2 != 0){
                fill(255,20);
              } else if(currentState % 2 == 0){
                fill(0, 102, 204, 20);
              }
            } else {
              noFill();
              noStroke();
            }
          } if(fingers == 2) {
            if(x > 10 && x < 260 && y > 270 && y < 570 || x > 240 && x < 330 && y < 560) {
              if(currentState % 2 != 0){
                fill(255,20);
              } else if(currentState % 2 == 0){
                fill(0, 102, 204, 20);
              }
            } else {
              noFill();
              noStroke();
            }
          } if(fingers == 3) {
            if(x > 90 && x < 500 && y > 560) {
              if(currentState % 2 != 0){
                fill(255,20);
              } else if(currentState % 2 == 0){
                fill(0, 102, 204, 20);
              }
            } else {
              noFill();
              noStroke();
            }
          } if(fingers == 4) {
            if(x > 302 && x < 638 && y > 389 && y < 554 || x > 480 && x < 680 && y > 555) {
              if(currentState % 2 != 0){
                fill(255,20);
              } else if(currentState % 2 == 0){
                fill(0, 102, 204, 20);
              }
            } else {
              noFill();
              noStroke();
            }
          } if (fingers >= 5) {
            if(currentState % 2 != 0){
              fill(255,20);
            } else if(currentState % 2 == 0){
              fill(0, 102, 204, 20);
            }
          }

//////////////// END OF PARAMETERS

          ellipse(x, y, (abs((rectY / 300) - 4)) * i, (abs((rectY / 300) - 4)) * i); // Size of explosion
          popStyle();
        }

        // deadnum += (int)random(-1,1);
        //println("run "+base.A+" : "+base.B);

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
}