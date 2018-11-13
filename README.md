# ZenWave
This project was done for my internship at Moxie as a Future Experiences Fellow. I used the Muse Headband to develop an experience that showcases the potential of Brain-Computer Interface.

This demo guides users through a series of actions to control the visuals on the wall through their brainwaves. Then they meditate for one minute using the visuals and audio cues. A visualization of their brainwave during the meditation will be shown on the web app in the end.

## Demo during Moxie All Access
The project was shwocased to 50+ participants during [Moxie All Access 2018](https://acreativepearphotography.pixieset.com/g/moxieallaccess2018/).
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
