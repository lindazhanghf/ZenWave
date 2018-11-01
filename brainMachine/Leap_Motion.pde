// MUSIC && CHANGE BOOLEANS

// int currentState = 1;
// boolean wait = false;

////////////////////////////

// void onFrame(final Controller controller) {

//   Frame frame = controller.frame();

//   HandList hands = frame.hands();

//   Hand firstHand = hands.get(0);

//   palmPosition= frame.hands().get(0).palmPosition();

//   filteredHandPosition = frame.hands().get(0).stabilizedPalmPosition();

//   handSphereRadius = frame.hands().get(0).sphereRadius();

//   rightHandCheck = frame.hands().get(0).isRight();

//   strength = frame.hands().get(0).grabStrength();

//   fingers = countExtendedFingers(controller);

//   // Increase sensitivity code
//   InteractionBox iBox = controller.frame().interactionBox();
//   Pointable pointable = controller.frame().pointables().frontmost();

//   leapPoint = frame.hands().get(0).palmPosition(); // Take palm position
//   normalizedPoint = iBox.normalizePoint(leapPoint, true);

//   normalizedPoint = normalizedPoint.times(1.28); // Scale here (The bigger the more sensitive)
//   normalizedPoint = normalizedPoint.minus(new Vector(.25, .25, .25)); // Re-center

//   for (Gesture gesture : frame.gestures()) {

//     if ("TYPE_CIRCLE".equals(gesture.type().toString()) && "STATE_START".equals(gesture.state().toString())) {
//       if(fingers == 1 && wait == false) {

//         changeGesture = true;
//         currentState += 1;

//         wait = true;

//         if (currentState % 2 != 0) {
//           humBrainLoop.loop(1);
//           artBrainLoop.stop();
//         } else if (currentState % 2 == 0) {
//           artBrainLoop.loop(2);
//           humBrainLoop.stop();
//         }

//       }
//     }



// //    println("gesture " + gesture + " id " + gesture.id() + " type " + gesture.type() + " state " + gesture.state() + " duration " + gesture.duration() + " durationSeconds " + gesture.durationSeconds());

// }

// }

// Finger counting
// int countExtendedFingers(final Controller controller) {
  // int fingers = 0;
  // if (controller.isConnected())
  // {
  //   Frame frame = controller.frame();
  //   if (!frame.hands().isEmpty())
  //   {
  //     for (Hand hand : frame.hands())
  //     {
  //       int extended = 0;
  //       for (Finger finger : hand.fingers())
  //       {
  //         if (finger.isExtended())
  //         {
  //           extended++;
  //         }
  //       }
  //       fingers = Math.max(fingers, extended);
  //     }
  //   }
  // }
  // return fingers;

//   return 5;
// }


// void onInit(final Controller controller) {
//   //controller.enableGesture(Gesture.Type.TYPE_CIRCLE);
//   //controller.enableGesture(Gesture.Type.TYPE_KEY_TAP);
//   //controller.enableGesture(Gesture.Type.TYPE_SCREEN_TAP);
//   //controller.enableGesture(Gesture.Type.TYPE_SWIPE);
//   // Enable background policy
//   controller.setPolicyFlags(Controller.PolicyFlag.POLICY_BACKGROUND_FRAMES);
// }