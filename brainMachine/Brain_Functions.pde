boolean resetDone = true;
int aiBrainX = 50;
int aiBrainY = 100;
int brainArea = 5;
boolean idleChange = false;

void resetNeurons() {
  
  if(rectY > 320){
    resetDone = true;
  }
    
  if(resetDone == true && currentState % 2 == 0 && rectY > 120) {
    
  currentState += 1;  
  println(currentState);
  humBrainLoop.loop(1);
  // artBrainLoop.stop();
    
  for(int i = 0; i < n.length; i++) { // Sections of Brain
    
    if(i < 4) {
      if(brainArea == 0) {
        n[i].x = 715; 
        n[i].y = 354;  
      } else if (fingers == 1) {
        n[i].x = 358; 
        n[i].y = 272;  
      } else if (fingers == 2) {
        n[i].x = 179; 
        n[i].y = 438;  
      } else if (fingers == 3) {
        n[i].x = 340; 
        n[i].y = 649;  
      } else if (fingers == 4) {
        n[i].x = 496; 
        n[i].y = 499;  
      } else if (fingers == 5) {
        n[i].x = width / 2; 
        n[i].y = height / 2;  
      }
      
    } else if (i >= 5 && i <= 180) {         
      n[i].x = random(500, 950); 
      n[i].y = random(125, 560);       
    } else if (i > 180 && i <= 280) {            
      n[i].x = random(164, 510); 
      n[i].y = random(120, 420);             
    } else if (i > 280 && i <= 380) {            
      n[i].x = random(88, 320); 
      n[i].y = random(290, 550);             
    } else if (i > 380 && i <= 480) {            
      n[i].x = random(140,495); 
      n[i].y = random(560,820);
    } else {
      n[i].x = random(302, 680); 
      n[i].y = random(390, 646);
      resetDone = false;
    }
    
  }
  
  fingerChange = false;
  
  for(int i = 0;i<n.length;i++) {
    n[i].makeSynapse();
  }
  
  for(int i = 0;i<n[0].s.length;i++){
    n[0].makeSignal(i);
  }
  
  }
  
 
//////////////////////////////////////////////////////////////  
// A.I BRAIN  
  
  
  // if(resetDone == true && currentState % 2 != 0 && rectY < 100) {
  // currentState += 1;
  // println(currentState);
  // artBrainLoop.loop(2);
  // humBrainLoop.stop();
    
  //  aiBrainX = 50;
  //  aiBrainY = 100;
    
  // for(int i = 0; i < n.length; i++) { // Sections of Brain
    
  //   if(i <= 1) {
  //     n[i].x = width / 2; 
  //     n[i].y = height / 2;  
  //   } else {
  //     n[i].x = aiBrainX += 50; 
  //     n[i].y = aiBrainY;
  //     resetDone = false;
      
  //     if(aiBrainX >= 950) {
  //       aiBrainY += 25;
  //       aiBrainX = 50;
  //     }
      
  //   }
    
  // }
  
  // for(int i = 0;i<n.length;i++) {
  //   n[i].makeSynapse();
  // }
  
  // for(int i = 0;i<n[0].s.length;i++){
  //   n[0].makeSignal(i);
  // }
  
  // }
  
  
   
}

//////////////////////////////////////////////////////////////  
// RESET BRAIN WHEN IDLE

void idleReset() {

int randomSpawn = int(random(0,5));

  if(idleChange == true) {
    for(int i = 0; i < n.length; i++) { // Sections of Brain
    
    if(i < 4) {
      if(randomSpawn == 0) {
        n[i].x = 715; 
        n[i].y = 354;  
      } else if (randomSpawn == 1) {
        n[i].x = 358; 
        n[i].y = 272;  
      } else if (randomSpawn == 2) {
        n[i].x = 179; 
        n[i].y = 438;  
      } else if (randomSpawn == 3) {
        n[i].x = 340; 
        n[i].y = 649;  
      } else if (randomSpawn == 4) {
        n[i].x = 496; 
        n[i].y = 499;  
      }
      
    } else if (i >= 5 && i <= 180) {         
      n[i].x = random(500, 950); 
      n[i].y = random(125, 560);       
    } else if (i > 180 && i <= 280) {            
      n[i].x = random(164, 510); 
      n[i].y = random(120, 420);             
    } else if (i > 280 && i <= 380) {            
      n[i].x = random(88, 320); 
      n[i].y = random(290, 550);             
    } else if (i > 380 && i <= 480) {            
      n[i].x = random(140,495); 
      n[i].y = random(560,820);
    } else {
      n[i].x = random(302, 680); 
      n[i].y = random(390, 646);
      resetDone = false;
    }
    
  }
  
  fingerChange = false;
  
  for(int i = 0;i<n.length;i++) {
    n[i].makeSynapse();
  }
  
  for(int i = 0;i<n[0].s.length;i++){
    n[0].makeSignal(i);
  }
  }
  
}