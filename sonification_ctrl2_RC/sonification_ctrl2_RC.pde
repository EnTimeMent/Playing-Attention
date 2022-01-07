// P(l)aying Attention Release Candidate
// Copyright (c) 2019, 2020 University College London
// Author: Nicolas Gold

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. 

// Note: this is a research prototype, not production-quality software. 
// Note: there are Windows-specific file separators in this prototype code.
// Note: see the README for information on using this code.

import controlP5.*;
import processing.sound.*;
import java.io.File;
import java.io.IOException;

ControlP5 cp5;
Button start, pause, cont, loadbutton, framePlay, framePause, frameReset, frameHalf, frameQuarter, frameUnity, frameReverse;
Slider frameSlider;
Table attention_data, figureJoints, arcData;
Group musicCtrlGroup, dataCtrlGroup, sonCtrlGroup, visGroup, playbackGroup;
Textlabel fileLabel, durationLabel, frameCountLabel, smoothingLabel, smoothingLabel2, frameStatus, multiplierLabel, toleranceLabel, mappingLabel, checkboxLabel;
CheckBox activeChannelSelect;
DropdownList mappingSelect, musicSet;
Numberbox smoothCount, tolerance, playbackSpeed;
Toggle displayProtective, sonifyProtective, sonPerspective;
boolean data_loaded, is_playing;
int globalCurrentPosition, globalFrameCount, playbackMultiplier;
float playbackIncrement;
final int maxPermittedFrames = 2000; 
Canvas visCanv;
float changeDataFrame = 0;
SoundFile[] clipArray;



void setup()
{
  background(0);
  size(800, 700);
  pixelDensity(2);
  frameRate(60);

  cp5 = new ControlP5(this);

  PFont newFont = createFont("Verdana", 8);
  ControlFont p5font = new ControlFont(newFont);
  cp5.setFont(p5font);
  Label.setUpperCaseDefault(false);

  data_loaded = false;
  globalCurrentPosition = 0;
  playbackMultiplier = 1;
  playbackIncrement = 1.0;

  setupMusicCtrls();
  setupDataCtrls();
  setupSonCtrls();
  setupFigureTable();
  setupArcData();
    
}

void draw()
{
  background(0);
  drawFigure();

  if (data_loaded) {
    float frameValue = frameSlider.getValue();
    globalCurrentPosition = round(map(frameValue, 0, frameSlider.getMax(), 0, globalFrameCount-1));
    if (globalCurrentPosition == globalFrameCount-1) {
      is_playing = false;
    }
    int channel;
    for (channel = 0; channel < 13; channel++){
           if (mappingSelect.getValue() == 0.0) {
             if (activeChannelSelect.getItem(channel).getBooleanValue()) {

               float attentionValue = attention_data.getFloat(channel, globalCurrentPosition);
               TableRow ad = arcData.getRow(channel);
               ad.setFloat("weight", attentionValue * 20.0);             
              }
              else
              {
                 TableRow ad = arcData.getRow(channel);
                 ad.setFloat("weight", 0.0);
              } 
           } else if (mappingSelect.getValue() == 1.0) {
              float totalAV;
              totalAV = 0.0;
              for (channel = 0; channel < 13; channel++){
                if (activeChannelSelect.getItem(channel).getBooleanValue()){
                  float attentionValue = attention_data.getFloat(channel, globalCurrentPosition);
                  totalAV += attentionValue;
                } 
              }
          
              if (totalAV == 0.0){
                totalAV = 1.0;
              }
    
              if (totalAV > 1.0) {
                println("rounding error?");
                totalAV = 1.0;
              }
  
           
              for (channel = 0; channel < 13; channel++){
                if (activeChannelSelect.getItem(channel).getBooleanValue()){
                  float attentionValue = attention_data.getFloat(channel, globalCurrentPosition);
                  TableRow ad = arcData.getRow(channel);
                  ad.setFloat("weight", map(attentionValue, 0.0, totalAV, 0.0, 20.0));             
                }
                else {
                  TableRow ad = arcData.getRow(channel);
                  ad.setFloat("weight", 0.0);
                }
              }
           } 
    } 

    if (!(displayProtective.getBooleanValue())) {
      if (attention_data.getInt(13, globalCurrentPosition) == 1){
        text("PROTECTIVE", 350, 350);
      }
    }   
  
    drawActiveArcs();
    setVolumes();

    if (is_playing){
      changeDataFrame = (changeDataFrame + playbackSpeed.getValue());
      if (changeDataFrame >= 1.0) {
        frameSlider.setValue(round(map(globalCurrentPosition + 1, 0, globalFrameCount-1, 0, frameSlider.getMax())));
        frameStatus.setText(str(globalCurrentPosition) + "/" + str(globalFrameCount-1));
        changeDataFrame = 0.0;
      }
    }
    
  } 
}

///////////////////////////////////////////////////////////////////////////////
void setupSonCtrls() {
  sonCtrlGroup = cp5.addGroup("sonCtrlGroup")
    .setPosition(10, 140)
    .setLabel("Sonification Control")
    .setBackgroundColor(color(60, 40, 0))
    .setBackgroundHeight(430)
    .hideArrow()
    .setBarHeight(25)
    .disableCollapse()
    .setWidth(220);

  playbackGroup = cp5.addGroup("playbackGroup")
    .setPosition(10,570)
    .hideArrow()
    .hideBar()
    .disableCollapse()
    .setWidth(width-20)
    .setBackgroundHeight(120)
    .setBackgroundColor(color(60,40,0));

  frameSlider = cp5.addSlider("Frame", 0, maxPermittedFrames, 0, 10, 50, 760, 20)
    .setSliderMode(Slider.FLEXIBLE)
    .showTickMarks(false)
    .setLabel("")
    .setGroup(playbackGroup);
  frameSlider.getValueLabel().setVisible(false);    

  activeChannelSelect = cp5.addCheckBox("checkBox")
    .setPosition(10, 40)
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .setSize(20, 20)
    .setItemsPerRow(1)
    .setSpacingColumn(30)
    .setSpacingRow(10)
    .addItem("L Full-body Flexion (26-1-4)", 0)  
    .addItem("R Full-body Flexion (26-1-9", 1) 
    .addItem("L Inner-body Flexion (12-1-3)", 2)
    .addItem("R Inner-body Flexion (12-1-8)", 3)
    .addItem("L Knee Angle (2-3-4)", 4)
    .addItem("R Knee Angle (7-8-9)", 5)
    .addItem("L Elbow Angle (15-16-17)", 6)
    .addItem("R Elbow Angle (20-21-22)", 7)
    .addItem("L Shoulder Angle (24-14-15)", 8)
    .addItem("R Shoulder Angle (24-19-20)", 9)
    .addItem("L Lateral Bend (16-14-2)", 10)
    .addItem("R Lateral Bend (21-19-7)", 11)
    .addItem("Neck Angle (12-24-26)", 12)
    .activateAll()
    .setGroup(sonCtrlGroup);

  activeChannelSelect.getItem(0).setColorCaptionLabel(color(255, 0, 0));
  activeChannelSelect.getItem(1).setColorCaptionLabel(color(0, 255, 0));
  activeChannelSelect.getItem(2).setColorCaptionLabel(color(222, 38, 158));
  activeChannelSelect.getItem(3).setColorCaptionLabel(color(149, 157, 234));
  activeChannelSelect.getItem(4).setColorCaptionLabel(color(220, 240, 17));
  activeChannelSelect.getItem(5).setColorCaptionLabel(color(17, 240, 223));
  activeChannelSelect.getItem(6).setColorCaptionLabel(color(240, 169, 17));
  activeChannelSelect.getItem(7).setColorCaptionLabel(color(203, 252, 150));
  activeChannelSelect.getItem(8).setColorCaptionLabel(color(245, 220, 236));
  activeChannelSelect.getItem(9).setColorCaptionLabel(color(58, 56, 232));
  activeChannelSelect.getItem(10).setColorCaptionLabel(color(75, 147, 18));
  activeChannelSelect.getItem(11).setColorCaptionLabel(color(234, 143, 140));
  activeChannelSelect.getItem(12).setColorCaptionLabel(color(19, 118, 101));
  
  mappingSelect = cp5.addDropdownList("mappingSelect")
    .setPosition(420,10)
    .addItem("Absolute", 0)
    .addItem("Active only", 1)
    .setItemHeight(20)
    .setOpen(false)
    .setBarHeight(20)
    .setGroup(playbackGroup)
    .setWidth(100)
    .setValue(0);
  mappingSelect.getCaptionLabel().set("Select scaling...");

  smoothingLabel = cp5.addTextlabel("smoothingLabel")
    .setText("Smooth")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(10,10);

  smoothCount = cp5.addNumberbox("smoothCount")
    .setValue(0)
    .setPosition(60,10)
    .setMultiplier(1.0)
    .setRange(0, maxPermittedFrames)
    .setGroup(playbackGroup);  
  smoothCount.getCaptionLabel().setVisible(false);

  smoothingLabel2 = cp5.addTextlabel("smoothingLabel2")
    .setText("frames")
    .setGroup(playbackGroup)
    .setSize(100,15)
    .setPosition(130,10);

  toleranceLabel = cp5.addTextlabel("toleranceLabel")
    .setText("Tolerance (%): ")
    .setGroup(playbackGroup)
    .setSize(100,15)
    .setPosition(190, 10);

  tolerance = cp5.addNumberbox("tolerance")
    .setValue(0)
    .setPosition(280,10)
    .setMultiplier(0.1)
    .setRange(0, 100)
    .setGroup(playbackGroup);  
  tolerance.getCaptionLabel().setVisible(false);
  
  framePlay = cp5.addButton("framePlay")
    .setSize(60, 30)
    .setPosition(10, 80)
    .setCaptionLabel("Play")
    .setGroup(playbackGroup);
  
  framePause = cp5.addButton("framePause")
    .setSize(60, 30)
    .setPosition(80, 80)
    .setCaptionLabel("Pause")
    .setGroup(playbackGroup);

  frameReset = cp5.addButton("frameReset")
    .setSize(60, 30)
    .setPosition(150, 80)
    .setCaptionLabel("Reset")
    .setGroup(playbackGroup);

  frameReverse = cp5.addButton("frameReverse")
    .setSize(60, 30)
    .setPosition(220, 80)
    .setCaptionLabel("Reverse")
    .setGroup(playbackGroup);
    
  frameUnity = cp5.addButton("frameUnity")
    .setSize(60, 30)
    .setPosition(330, 80)
    .setCaptionLabel("1")
    .setGroup(playbackGroup);

  frameHalf = cp5.addButton("frameHalf")
    .setSize(60, 30)
    .setPosition(400, 80)
    .setCaptionLabel("1/2")
    .setGroup(playbackGroup);
  
  frameQuarter = cp5.addButton("frameQuarter")
    .setSize(60, 30)
    .setPosition(470, 80)
    .setCaptionLabel("1/4")
    .setGroup(playbackGroup);

  playbackSpeed = cp5.addNumberbox("playbackSpeed")
    .setValue(1.0)
    .setPosition(670,80)
    .setMultiplier(0.1)
    .setRange(0,5)
    .setGroup(playbackGroup);  
  playbackSpeed.getCaptionLabel().setVisible(false);

  multiplierLabel = cp5.addTextlabel("multiplierLabel")
    .setText("Frame playback speed")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(560,80);

  mappingLabel = cp5.addTextlabel("mappingLabel")
    .setText("Scaling: ")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(370,10);

  checkboxLabel = cp5.addTextlabel("checkboxLabel")
    .setText("Active channels (white=active)")
    .setGroup(sonCtrlGroup)
    .setSize(50,15)
    .setPosition(10,10);
    
  frameStatus = cp5.addTextlabel("frameStatus")
    .setText("0/0")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(740, 70);
    
  displayProtective = cp5.addToggle("displayProtective")
    .setLabel("Show Protective")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(550,10)
    .setMode(ControlP5.SWITCH);

  sonifyProtective = cp5.addToggle("sonifyProtective")
    .setLabel("Sonify Protective")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(620,10)
    .setMode(ControlP5.SWITCH);

  sonifyProtective = cp5.addToggle("sonPerspective")
    .setLabel("Patient|Observer")
    .setGroup(playbackGroup)
    .setSize(50,15)
    .setPosition(700,10)
    .setMode(ControlP5.SWITCH);

  visCanv = new MyCanvas();
  visCanv.pre();
  cp5.addCanvas(visCanv);
  
  
  frameQuarter.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      playbackSpeed.setValue(0.25);
    }
  }
  );
  
  frameHalf.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      playbackSpeed.setValue(0.5);
    }
  }
  );
  
  frameUnity.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      playbackSpeed.setValue(1.0);
    }
  }
  );

  framePlay.onRelease(new CallbackListener () {
    public void controlEvent(CallbackEvent theEvent) {
      is_playing = true;
    }
  }
  );
  
  framePause.onRelease(new CallbackListener () {
    public void controlEvent(CallbackEvent theEvent) {
      is_playing = false;
    }
  }
  );

  frameReset.onRelease(new CallbackListener () {
    public void controlEvent(CallbackEvent theEvent) {
      is_playing = false;
      frameSlider.setValue(0);
      frameStatus.setText("0/" + str(globalFrameCount-1));
      globalCurrentPosition = 0;
    }
  }
  );

  
}


///////////////////////////////////////////////////////////////////////////////

void setupDataCtrls() {
  dataCtrlGroup = cp5.addGroup("dataCtrlGroup")
    .setPosition(10, 40)
    .setLabel("Data Control")
    .setBackgroundColor(color(60, 40, 0))
    .setBackgroundHeight(60)
    .setWidth(530)
    .hideArrow()
    .disableCollapse()
    .setBarHeight(25);

  loadbutton = cp5.addButton("Load data")
    .setGroup(dataCtrlGroup)  
    .setSize(100, 30)
    .setPosition(10, 15);

  fileLabel = cp5.addTextlabel("fileLabel")
    .setText("File: ")
    .setGroup(dataCtrlGroup)
    .setSize(400, 15)
    .setPosition(120, 5);

  durationLabel = cp5.addTextlabel("durationLabel")
    .setText("Duration: ")
    .setGroup(dataCtrlGroup)
    .setSize(150, 15)
    .setPosition(120, 25);

  frameCountLabel = cp5.addTextlabel("frameCountLabel")
    .setText("Frame Count: ")
    .setGroup(dataCtrlGroup)
    .setSize(150, 15)
    .setPosition(280, 25);

  loadbutton.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      selectInput("Select data file:", "fileSelected");
    }
  }
  );
}


void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else 
  {
    println("User selected " + selection.getAbsolutePath());
    try {
      attention_data = new Table(new File(selection.getAbsolutePath()));
      globalFrameCount = attention_data.getColumnCount();
      fileLabel.setText("File: " + selection.getName());
      frameCountLabel.setText("Frame Count: " + str(globalFrameCount));
      durationLabel.setText("Duration: " + str(round((globalFrameCount / 60.0) * 100.0) / 100.0));
      frameStatus.setText("0/" + str(globalFrameCount-1));
      data_loaded = true;
    } 
    catch (IOException e) {
    }
  }
}

/////////////////////////////////////////////////////////////////


void setupMusicCtrls() {
  musicCtrlGroup = cp5.addGroup("musicCtrlGroup")
    .setPosition(width-10-240, 40)
    .setLabel("Music Control")
    .setBackgroundColor(color(60, 40, 0))
    .setBackgroundHeight(100)
    .setWidth(240)
    .hideArrow()
    .disableCollapse()
    .setBarHeight(25);

  start = cp5.addButton("Start").setSize(60, 30).setPosition(10, 15).setGroup(musicCtrlGroup);
  pause = cp5.addButton("Pause").setSize(60, 30).setPosition(80, 15).setGroup(musicCtrlGroup);
  cont = cp5.addButton("Continue").setSize(80, 30).setPosition(150, 15).setGroup(musicCtrlGroup);

  musicSet = cp5.addDropdownList("Music Set")
          .setSize(150, 100)
          .setPosition(10,70)
          .setItemHeight(20)
          .setGroup(musicCtrlGroup)
          .setOpen(true)
          .setBarHeight(20)
          .setWidth(200)
          .setValue(0.0);

  musicSet.addItem("Percussion", 0);
  musicSet.addItem("Canon", 1);

  musicSet.getCaptionLabel().set("Select music...");

  StringBuilder prefix;
  prefix = new StringBuilder("data");
 
  if ((int)musicSet.getValue() == 0){
     prefix.append("/perc");
  }
  else{
    prefix.append("/canon");
  }
    
  clipArray = new SoundFile[13];
  int panFlag = -1;
  
  for (int channel = 0; channel < 13; channel++){
      clipArray[channel] = new SoundFile(this, prefix.toString() + "/" + str(channel) + ".wav");  
      clipArray[channel].pan(panFlag);
      panFlag = panFlag * -1;
  }

  start.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      for (int channel = 0; channel < 13; channel++){
        clipArray[channel].stop();
        clipArray[channel].loop();
      }
    }
  }
  );

  pause.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      for (int channel = 0; channel < 13; channel++){
        clipArray[channel].pause();
      }
    }
  }
);


  final PApplet myApplet = this;

  musicSet.onRelease(new CallbackListener() {  
                      public void controlEvent(CallbackEvent theEvent) {
                          int panFlag = -1;
                          for (int channel = 0; channel < 13; channel++) {
                              StringBuilder replPrefix = new StringBuilder("data"); 
                                if ((int)musicSet.getValue() == 0){
                                   replPrefix.append("/perc");
                                }
                                else{
                                  replPrefix.append("/canon");
                                }
                              clipArray[channel].stop();
                              clipArray[channel] = new SoundFile(myApplet, replPrefix.toString() + "/" + str(channel) + ".wav");
                              clipArray[channel].pan(panFlag);
                              panFlag = panFlag * -1;
                          }
                      }
                  }
  );


  cont.onRelease(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      for (int channel = 0; channel < 13; channel++){
        clipArray[channel].loop();
      }
    }
  }
  );
}




void drawActiveArcs(){
  int xFigureOrigin = 500;
  int yFigureOrigin = 280;

  int x1, x2, x3, x4, y1, y2, y3, y4;
  int j1, j2, j3, r, g, b; 
  float w;
 
     
  for (int channel=0; channel <13; channel++){
    w = arcData.getFloat(channel, "weight");
    if (w != 0.0) {
      j1 = arcData.getInt(channel, "j1");
      j2 = arcData.getInt(channel, "j2");
      j3 = arcData.getInt(channel, "j3");
      r = arcData.getInt(channel, "r");
      g = arcData.getInt(channel, "g");
      b = arcData.getInt(channel, "b");

      x1 = xFigureOrigin + figureJoints.getInt(j1-1, "x");
      y1 = yFigureOrigin + figureJoints.getInt(j1-1, "y");
      x2 = xFigureOrigin + figureJoints.getInt(j2-1, "x");
      y2 = yFigureOrigin + figureJoints.getInt(j2-1, "y");
      x3 = x2;
      y3 = y2;
      x4 = xFigureOrigin + figureJoints.getInt(j3-1, "x");
      y4 = yFigureOrigin + figureJoints.getInt(j3-1, "y");

      strokeWeight(w);
      stroke(color(r,g,b));
      bezier(x1,y1,x2,y2,x3,y3,x4,y4);
    }
  }
}


void drawFigure(){
  int xFigureOrigin = 500;
  int yFigureOrigin = 280;
  int x1, y1, x2, y2 = 0;

  strokeWeight(1);
  stroke(255);
  noFill();
  
  // 12->1  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(11, "x");
  y1 = yFigureOrigin + figureJoints.getInt(11, "y");
  x2 = xFigureOrigin + figureJoints.getInt(0, "x");
  y2 = yFigureOrigin + figureJoints.getInt(0, "y");
  line(x1, y1, x2, y2); 
  circle(x1, y1, 10);
  text("12", x1+7, y1);
  circle(x2, y2, 10);
  text("1", x2+7, y2);
  
  // 1->2  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(0, "x");
  y1 = yFigureOrigin + figureJoints.getInt(0, "y");
  x2 = xFigureOrigin + figureJoints.getInt(1, "x");
  y2 = yFigureOrigin + figureJoints.getInt(1, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("2", x2+7, y2);
  
  // 2->3  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(1, "x");
  y1 = yFigureOrigin + figureJoints.getInt(1, "y");
  x2 = xFigureOrigin + figureJoints.getInt(2, "x");
  y2 = yFigureOrigin + figureJoints.getInt(2, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("3", x2+7, y2);

  // 3->4  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(2, "x");
  y1 = yFigureOrigin + figureJoints.getInt(2, "y");
  x2 = xFigureOrigin + figureJoints.getInt(3, "x");
  y2 = yFigureOrigin + figureJoints.getInt(3, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("4", x2+7, y2);

  // 4->5  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(3, "x");
  y1 = yFigureOrigin + figureJoints.getInt(3, "y");
  x2 = xFigureOrigin + figureJoints.getInt(4, "x");
  y2 = yFigureOrigin + figureJoints.getInt(4, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);

  // 5->6  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(4, "x");
  y1 = yFigureOrigin + figureJoints.getInt(4, "y");
  x2 = xFigureOrigin + figureJoints.getInt(5, "x");
  y2 = yFigureOrigin + figureJoints.getInt(5, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);

  // 1->7  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(0, "x");
  y1 = yFigureOrigin + figureJoints.getInt(0, "y");
  x2 = xFigureOrigin + figureJoints.getInt(6, "x");
  y2 = yFigureOrigin + figureJoints.getInt(6, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  circle(x1, y1, 10);
  text("7", x2+7, y2+3);

  // 7->8  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(6, "x");
  y1 = yFigureOrigin + figureJoints.getInt(6, "y");
  x2 = xFigureOrigin + figureJoints.getInt(7, "x");
  y2 = yFigureOrigin + figureJoints.getInt(7, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("8", x2+7, y2+3);

  // 8->9  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(7, "x");
  y1 = yFigureOrigin + figureJoints.getInt(7, "y");
  x2 = xFigureOrigin + figureJoints.getInt(8, "x");
  y2 = yFigureOrigin + figureJoints.getInt(8, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("9", x2+7, y2+3);

  // 9->10  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(8, "x");
  y1 = yFigureOrigin + figureJoints.getInt(8, "y");
  x2 = xFigureOrigin + figureJoints.getInt(9, "x");
  y2 = yFigureOrigin + figureJoints.getInt(9, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  
  // 10->11  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(9, "x");
  y1 = yFigureOrigin + figureJoints.getInt(9, "y");
  x2 = xFigureOrigin + figureJoints.getInt(10, "x");
  y2 = yFigureOrigin + figureJoints.getInt(10, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);

  // 12->13  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(11, "x");
  y1 = yFigureOrigin + figureJoints.getInt(11, "y");
  x2 = xFigureOrigin + figureJoints.getInt(12, "x");
  y2 = yFigureOrigin + figureJoints.getInt(12, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("13", x2+7, y2+7);

  // 13->14  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(12, "x");
  y1 = yFigureOrigin + figureJoints.getInt(12, "y");
  x2 = xFigureOrigin + figureJoints.getInt(13, "x");
  y2 = yFigureOrigin + figureJoints.getInt(13, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("14", x2+7, y2);

  // 14->15  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(13, "x");
  y1 = yFigureOrigin + figureJoints.getInt(13, "y");
  x2 = xFigureOrigin + figureJoints.getInt(14, "x");
  y2 = yFigureOrigin + figureJoints.getInt(14, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("15", x2+7, y2);

  // 15->16  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(14, "x");
  y1 = yFigureOrigin + figureJoints.getInt(14, "y");
  x2 = xFigureOrigin + figureJoints.getInt(15, "x");
  y2 = yFigureOrigin + figureJoints.getInt(15, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("16", x2+7, y2);

  // 16->17  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(15, "x");
  y1 = yFigureOrigin + figureJoints.getInt(15, "y");
  x2 = xFigureOrigin + figureJoints.getInt(16, "x");
  y2 = yFigureOrigin + figureJoints.getInt(16, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("17", x2+7, y2);

  // 17->18  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(16, "x");
  y1 = yFigureOrigin + figureJoints.getInt(16, "y");
  x2 = xFigureOrigin + figureJoints.getInt(17, "x");
  y2 = yFigureOrigin + figureJoints.getInt(17, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("18", x2+7, y2);

  // 13->19  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(12, "x");
  y1 = yFigureOrigin + figureJoints.getInt(12, "y");
  x2 = xFigureOrigin + figureJoints.getInt(18, "x");
  y2 = yFigureOrigin + figureJoints.getInt(18, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("19", x2-20, y2);

  // 19->20  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(18, "x");
  y1 = yFigureOrigin + figureJoints.getInt(18, "y");
  x2 = xFigureOrigin + figureJoints.getInt(19, "x");
  y2 = yFigureOrigin + figureJoints.getInt(19, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("20", x2+7, y2+7);

  // 20->21  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(19, "x");
  y1 = yFigureOrigin + figureJoints.getInt(19, "y");
  x2 = xFigureOrigin + figureJoints.getInt(20, "x");
  y2 = yFigureOrigin + figureJoints.getInt(20, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("21", x2+7, y2);
  
  // 21->22  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(20, "x");
  y1 = yFigureOrigin + figureJoints.getInt(20, "y");
  x2 = xFigureOrigin + figureJoints.getInt(21, "x");
  y2 = yFigureOrigin + figureJoints.getInt(21, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("22", x2+7, y2);

  // 22->23  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(21, "x");
  y1 = yFigureOrigin + figureJoints.getInt(21, "y");
  x2 = xFigureOrigin + figureJoints.getInt(22, "x");
  y2 = yFigureOrigin + figureJoints.getInt(22, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("23", x2+7, y2);

  // 13->24  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(12, "x");
  y1 = yFigureOrigin + figureJoints.getInt(12, "y");
  x2 = xFigureOrigin + figureJoints.getInt(23, "x");
  y2 = yFigureOrigin + figureJoints.getInt(23, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("24", x2+7, y2);

  // 24->25  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(23, "x");
  y1 = yFigureOrigin + figureJoints.getInt(23, "y");
  x2 = xFigureOrigin + figureJoints.getInt(24, "x");
  y2 = yFigureOrigin + figureJoints.getInt(24, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("25", x2+7, y2);

  // 24->25  (remember -1 offset on indices)
  x1 = xFigureOrigin + figureJoints.getInt(24, "x");
  y1 = yFigureOrigin + figureJoints.getInt(24, "y");
  x2 = xFigureOrigin + figureJoints.getInt(25, "x");
  y2 = yFigureOrigin + figureJoints.getInt(25, "y");
  line(x1, y1, x2, y2); 
  circle(x2, y2, 10);
  text("26", x2+7, y2);

}


void setupArcData(){
  arcData = new Table();
  arcData.addColumn("j1");
  arcData.addColumn("j2");
  arcData.addColumn("j3");
  arcData.addColumn("r");
  arcData.addColumn("g");
  arcData.addColumn("b");
  arcData.addColumn("weight");
  
  TableRow a = arcData.addRow();
  a.setInt("j1", 26);
  a.setInt("j2", 1);
  a.setInt("j3", 4);
  a.setInt("r", 255);
  a.setInt("g", 0);
  a.setInt("b", 0);
  a.setFloat("weight",0.0);
    
  a = arcData.addRow();
  a.setInt("j1", 26);
  a.setInt("j2", 1);
  a.setInt("j3", 9);
  a.setInt("r", 0);
  a.setInt("g", 255);
  a.setInt("b", 0);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 12);
  a.setInt("j2", 1);
  a.setInt("j3", 3);
  a.setInt("r", 222);
  a.setInt("g", 38);
  a.setInt("b", 158);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 12);
  a.setInt("j2", 1);
  a.setInt("j3", 8);
  a.setInt("r", 149);
  a.setInt("g", 157);
  a.setInt("b", 234);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 2);
  a.setInt("j2", 3);
  a.setInt("j3", 4);
  a.setInt("r", 220);
  a.setInt("g", 240);
  a.setInt("b", 17);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 7);
  a.setInt("j2", 8);
  a.setInt("j3", 9);
  a.setInt("r", 17);
  a.setInt("g", 240);
  a.setInt("b", 223);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 15);
  a.setInt("j2", 16);
  a.setInt("j3", 17);
  a.setInt("r", 240);
  a.setInt("g", 169);
  a.setInt("b", 17);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 20);
  a.setInt("j2", 21);
  a.setInt("j3", 22);
  a.setInt("r", 203);
  a.setInt("g", 252);
  a.setInt("b", 150);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 24);
  a.setInt("j2", 14);
  a.setInt("j3", 15);
  a.setInt("r", 245);
  a.setInt("g", 220);
  a.setInt("b", 236);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 24);
  a.setInt("j2", 19);
  a.setInt("j3", 20);
  a.setInt("r", 58);
  a.setInt("g", 56);
  a.setInt("b", 232);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 16);
  a.setInt("j2", 14);
  a.setInt("j3", 2);
  a.setInt("r", 75);
  a.setInt("g", 147);
  a.setInt("b", 18);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 21);
  a.setInt("j2", 19);
  a.setInt("j3", 7);
  a.setInt("r", 234);
  a.setInt("g", 143);
  a.setInt("b", 140);
  a.setFloat("weight",0.0);

  a = arcData.addRow();
  a.setInt("j1", 12);
  a.setInt("j2", 24);
  a.setInt("j3", 26);
  a.setInt("r", 19);
  a.setInt("g", 118);
  a.setInt("b", 101);
  a.setFloat("weight",0.0);
    
}

void setupFigureTable(){
  // set up figure
  figureJoints = new Table();
  figureJoints.addColumn("x");
  figureJoints.addColumn("y");
  
  int spacing = 45;

  // Joint 1 offsets 0x, 1y
  TableRow newRow1 = figureJoints.addRow();
  newRow1.setInt("x", 0);
  newRow1.setInt("y", spacing);

  // Joint 2 offsets 1x, 2y
  TableRow newRow2 = figureJoints.addRow();
  newRow2.setInt("x", spacing);
  newRow2.setInt("y", spacing * 2);

  // Joint 3 offsets 1.5x, 3y
  TableRow newRow3 = figureJoints.addRow();
  newRow3.setInt("x", spacing + int((0.5 * spacing)));
  newRow3.setInt("y", spacing * 3);

  // Joint 4 offsets 1x, 4y
  TableRow newRow4 = figureJoints.addRow();
  newRow4.setInt("x", spacing + int((0.25 * spacing)));
  newRow4.setInt("y", spacing * 4);

  // Joint 5 offsets - unlabelled in diagram - left ankle 
  TableRow newRow5 = figureJoints.addRow();
  newRow5.setInt("x", spacing);
  newRow5.setInt("y", int((spacing * 4) + 0.5 * spacing));
  
  // Joint 6 offsets - unlabelled in diagram - left foot 
  TableRow newRow6 = figureJoints.addRow();
  newRow6.setInt("x", spacing + int((0.5 * spacing)));
  newRow6.setInt("y", (spacing * 5) - int((0.25 * spacing)));
  
  // Joint 7 offsets 
  TableRow newRow7 = figureJoints.addRow();
  newRow7.setInt("x", -1 * spacing);
  newRow7.setInt("y", spacing * 2);

  // Joint 8 offsets
  TableRow newRow8 = figureJoints.addRow();
  newRow8.setInt("x", -1 * (spacing + int((0.5 * spacing))));
  newRow8.setInt("y", spacing * 3);
  
  // Joint 9 offsets
  TableRow newRow9 = figureJoints.addRow();
  newRow9.setInt("x", -1 * (spacing + int((0.5 * spacing))));
  newRow9.setInt("y", spacing * 4);
  
  // Joint 10 offsets - unlabelled in diagram - right ankle
  TableRow newRow10 = figureJoints.addRow();
  newRow10.setInt("x", -1 * (spacing + int((0.75 * spacing))));
  newRow10.setInt("y", (spacing * 4) + int(0.5 * spacing));
  
  // Joint 11 offsets - unlabelled in diagram - right foot
  TableRow newRow11 = figureJoints.addRow();
  newRow11.setInt("x", -1 * int((0.75 * spacing)));
  newRow11.setInt("y", (spacing * 5) - int((0.25 * spacing)));

  // Joint 12 offsets
  TableRow newRow12 = figureJoints.addRow();
  newRow12.setInt("x", 0);
  newRow12.setInt("y", 0);

  // Joint 13 offsets
  TableRow newRow13 = figureJoints.addRow();
  newRow13.setInt("x", 0);
  newRow13.setInt("y", -1 * spacing);

  // Joint 14 offsets
  TableRow newRow14 = figureJoints.addRow();
  newRow14.setInt("x", spacing);
  newRow14.setInt("y", -1 * (spacing + int((0.5 * spacing))));

  // Joint 15 offsets
  TableRow newRow15 = figureJoints.addRow();
  newRow15.setInt("x", 2 * spacing);
  newRow15.setInt("y", -1 * spacing);

  // Joint 16 offsets
  TableRow newRow16 = figureJoints.addRow();
  newRow16.setInt("x", (2 * spacing) - int((0.25 * spacing)));
  newRow16.setInt("y", 0);

  // Joint 17 offsets
  TableRow newRow17 = figureJoints.addRow();
  newRow17.setInt("x", 2 * spacing);
  newRow17.setInt("y", spacing);

  // Joint 18 offsets
  TableRow newRow18 = figureJoints.addRow();
  newRow18.setInt("x", (2 * spacing) + int((0.75 * spacing)));
  newRow18.setInt("y", (2 * spacing) - int((0.5 * spacing)));

  // Joint 19 offsets
  TableRow newRow19 = figureJoints.addRow();
  newRow19.setInt("x", -1 * spacing + int((0.25 * spacing)));
  newRow19.setInt("y", -1 * (spacing + int((0.5 * spacing))));

  // Joint 20 offsets
  TableRow newRow20 = figureJoints.addRow();
  newRow20.setInt("x", -1 * 2 * spacing);
  newRow20.setInt("y", -1 * spacing);

  // Joint 21 offsets
  TableRow newRow21 = figureJoints.addRow();
  newRow21.setInt("x", -1 * 2 * spacing);
  newRow21.setInt("y", 0);

  // Joint 22 offsets
  TableRow newRow22 = figureJoints.addRow();
  newRow22.setInt("x", -1 * (spacing + int((0.25 * spacing))));
  newRow22.setInt("y", (spacing - int((0.25 * spacing))));

  // Joint 23 offsets
  TableRow newRow23 = figureJoints.addRow();
  newRow23.setInt("x", -1 * int(0.75 * spacing));
  newRow23.setInt("y", spacing);

  // Joint 24 offsets
  TableRow newRow24 = figureJoints.addRow();
  newRow24.setInt("x", -1 * int((0.4 * spacing)));
  newRow24.setInt("y", -1 * (spacing + int((0.75 * spacing))));

  // Joint 25 offsets
  TableRow newRow25 = figureJoints.addRow();
  newRow25.setInt("x", 0);
  newRow25.setInt("y", -1 * ((2 * spacing) + int(0.5 * spacing)));

  // Joint 26 offsets
  TableRow newRow26 = figureJoints.addRow();
  newRow26.setInt("x", -1 * int((0.5 * spacing)));
  newRow26.setInt("y", -1 * int((3 * spacing)));
}

void setVolumes(){
  float totalAV;
  if (mappingSelect.getValue() == 1.0) {
     totalAV = 0.0;
     for (int channel = 0; channel < 13; channel++){
        if (activeChannelSelect.getItem(channel).getBooleanValue()){
          float attentionValue = attention_data.getFloat(channel, globalCurrentPosition);
          totalAV += attentionValue;
     }
  }
  }
  else{
    totalAV = 1.0;
  }
  
  if (totalAV == 0.0){
    totalAV = 1.0;
  }
  
  if (totalAV > 1.0) {
    totalAV = 1.0;
  }
    
  for (int channel = 0; channel < 13; channel++){
    if (activeChannelSelect.getItem(channel).getBooleanValue()){
      float attentionValue = attention_data.getFloat(channel, globalCurrentPosition);  
      clipArray[channel].amp(map(attentionValue, 0.0, totalAV, 0.0, 1.0));
    }
    else{
      clipArray[channel].amp(0.0);      
    }
  }    
    
  }


class MyCanvas extends Canvas {

  public void setup(PGraphics pg) {
  }  

  public void update(PApplet p) {
  }

  public void draw(PGraphics pg) {
  }
}
