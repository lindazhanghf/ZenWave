# ZenWave
This project was done for my internship at Moxie as a Future Experiences Fellow. I used the Muse Headband to develop an experience that showcases the potential of Brain-Computer Interface.

This demo guides users through a series of actions to control the visuals on the wall through their brainwaves. Then they meditate for one minute using the visuals and audio cues. A visualization of their brainwave during the meditation will be shown on the web app in the end.

## Demo during Moxie All Access
The project was showcased to 50+ participants during [Moxie All Access 2018](https://acreativepearphotography.pixieset.com/g/moxieallaccess2018/).
<p float="left">
  <img src="http://www.ziyinzhang.com/project/image/brain-machine/showcase.jpg" width="430" />
  <img src="http://www.ziyinzhang.com/project/image/brain-machine/showcase2.jpg" width="430" /> 
</p>

## Project Overview 
This project consists of two parts: FrontPosterMoxie and Muse diagram. 

FrontPosterMoxie is based on the Processing script provided by Pedro Arevalo. This part is essential for the experience. It does the following: 
1. Receive data from one or multiple Muse Headbands via OSC 
2. Display the data in the Processing window, and projected via MadMapper 2 
3. Send data to Muse Diagram to visualize the data in the web browser 

Muse Diagram is a simple web app created using Node.js. This part is *not* essential for the experience. It does the following: 
1. Receive data from FrontPosterMoxie via OSC 
2. Display information of Muse Head

### Set Up
On a Windows 10 machine, install the following software: 
- Muse Direct (available in Miscrosoft Store) 
- Node.js latest stable build
- Processing (version 3.0+), and the latest libraries: 
   - Sound 
   - OSCP5 
   - Syphon (used to send screen to MadMapper) 

Download the repository. Open a terminal, navigate to the folder *brainDiagram* and run:
```
npm install
```

### Preparation

Connect the headbands to Muse Direct (see appendix for detailed connection instruction) or [Muse Monitor](https://musemonitor.com/). Start OSC stream.

Run FrontPosterMoxie. You should be able to see the neurons moving slightly if it’s connected. 

Open a terminal, navigate to the folder *brainDiagram* and run:
```
node brain_diagram.js
```

A web page should pop up automatically, just wait for a few seconds for it to render or refresh. If nothing shows up, open a web browser, type http://localhost:3000/ in the address bar. You should be able to see the default view of the web app like this: 
![Default view of web app](http://www.ziyinzhang.com/project/image/brain-machine/web_app_default.png)

### Instructions for each state in the experience

#### Idle
Put on the Muse Headband.

#### Fitting

Use the image of the headband on the web app to get the best fit. Here is a video guide to wear the headband properly:
<p float="left">
  <img herf=“https://youtu.be/v8xUYqqJAIg” target="_blank" src="https://img.youtube.com/vi/v8xUYqqJAIg/0.jpg" width="300" />
  <img src="http://www.ziyinzhang.com/project/image/brain-machine/web_app_fitting.png" width="330" /> 
</p>

&nbsp;&nbsp;&nbsp;&nbsp; [*Adjusting and fitting tips for Muse*](https://youtu.be/v8xUYqqJAIg) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; *Headband fitting information*
 
There are 4 sensors on the headband, two on the forehead and two behind the ears. The color overlay on the sensors shows: 
- **Semi-transparent red**: headband not on; not in contact with the skin 
- **Red**: bad fitting 
- **Green**: good fitting 

Once all sensors are green, the user can continue to the next state. Press ```Enter``` to continue (make sure the processing window is selected).

#### Calibration 

The headband needs to calibrate for 15~20 seconds. During this state, the users are required to close his/her eyes, sit still, and not moving any facial muscle. Calibration data will only be collected when 3 or more sensors are shown green.  

After 70 data points are collected, the calibration state ends. An average of Beta absolute power collected throughout the state will be calculated as the baseline for the preceding states. 

#### Tutorial 

During this state, the program will explain the basis of brainwave and guide user through 3 interactions using voice cues. 

1. Eyes closed 
2. Rapid eye movement 
3. Concentration 

```Nod one time``` 
After each interaction, the tutorial is paused to allow the users to practice the interaction. To proceed, users need to nod their head. How fast the users need to nod to trigger the event is defined by the variable “gyro_threshold” in Muse_Reader.pde; the current setting is 30 angular velocity.

#### Meditation  

The users are instructed to meditate for one minute. Essentially the users can do whatever they want, either opening or closing their eyes. Alpha and Beta Band Power are collected and use for calculation of the “relaxed state”. 

#### Result – Brain Diagram 
![Result of web app](http://www.ziyinzhang.com/project/image/brain-machine/web_app_result.png)

Result of the one minute meditation are shown in Brain Diagram as two charts: 

- MEDITATION RESULT 
   - Doughnut chart (pie chart) 
   - Shows the percentage of time relaxed verses alert, I.e. how well the user has done during the meditation 
- MEDITATION DATA  
   - Line chart 
   - Display the data collected during meditation (0 - 60 seconds). Hover the mouse on the line chart to see the detailed data of specific time stamp 

| Name | Style | Type of Data |
| ---  |  ---  |      ---     |
| Alpha absolute | light blue line     | Alpha absolute power   |
| Beta absolute | orange line     | Beta absolute power   |
| Relaxed     | dark blue filled area | Peirods that the user is relaxed; defined by Beta < Alpha, Baseline      |
| Baseline | white straight line     | Baseline of Beta absolute, calcutaed from calibration   |

Press ```Enter``` in FrontPosterMoxie to restart the experience. 

#### Other Controls 
```Space bar``` toggle between the two devices. You can see which one is currently being used on the web app, highlighted in blue. 

```N``` fires a nodding event to proceed to next interaction or to skip an audio cue. This can also be initiated by nod one time in a faster pace (defined by “gyro_threshold_strict” with an angular velocity of 60). 

```Enter``` skip to next state. The program will try to calculate and display data as normal. 

```\ Backslash``` go back to the previous state. Only use during Calibration state to restart calibtration.

### Additional Notes  

#### Muse Direct setting 

| Setting  |  |
| ---      | ---       |
| Type     | OSC UDP   |
| Port     | 7000      |
| Prefix   | Muse_black|
| Output Data (checked)| <lu><li>Gyroscope </li></lu> |
| Output Algorithm (checked) |<lu><li>Absolute Band Powers </li><li>Band Power Score </li><li>HSI Precision </li><li>Is Good  </li><li>Headband On </li></lu> |

#### Notes for connecting to multiple Muse Headbands 

An issue was found when connecting 2 headbands to Muse Direct at once. Bluetooth transmissions seems to interfere with one another. To avoid this issue, I am using [Muse Monitor](https://musemonitor.com/) as a backup during All Access. My setup was like this: 
```
1st Muse Headband —[Bluetooth]—> Muse Direct (Win 10) —[OSC]—> Mac Mini  
```
```
2nd Muse Headband —[Bluetooth]—> Muse Monitor (iOS) —[OSC]—> Mac Mini 
```
