/*
 
 Modified by Matt McWilliams 2021

 stipple_gen

 This application is intended to replace the original UI of StippleGen_2 with
 a simple Processing application that can be run using command line arguments or
 a config file. Arguments take precedence over the config file.

 Why do it this way? So that the stippling process can be run headless with a config file
 or command line arguments. Why do that? So this application can be used for
 automated image generation.

 License: LGPL 2.1

 *******************************************************************************
 HISTORY
 *******************************************************************************

 Program is based on StippleGen_2 
 
 SVG Stipple Generator, v. 2.31
 Copyright (C) 2013 by Windell H. Oskay, www.evilmadscientist.com
 
 Full Documentation: http://wiki.evilmadscience.com/StippleGen
 Blog post about the release: http://www.evilmadscientist.com/go/stipple2
 
 An implementation of Weighted Voronoi Stippling:
 http://mrl.nyu.edu/~ajsecord/stipples.html
 
 *******************************************************************************
 
 StippleGen_2 is based on the Toxic Libs Library ( http://toxiclibs.org/ )
 & example code:
 http://forum.processing.org/topic/toxiclib-voronoi-example-sketch
 
 Additional inspiration:
 Stipple Cam from Jim Bumgardner
 http://joyofprocessing.com/blog/2011/11/stipple-cam/
 
 and 
 
 MeshLibDemo.pde - Demo of Lee Byron's Mesh library, by 
 Marius Watz - http://workshop.evolutionzone.com/
 
 Requires Toxic Libs library:
 http://hg.postspectacular.com/toxiclibs/downloads
 
 */

/*  
 * 
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * http://creativecommons.org/licenses/LGPL/2.1/
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */ 

import toxi.geom.*;
import toxi.geom.mesh2d.*;
import toxi.util.datatypes.*;
import toxi.processing.*;

ToxiclibsSupport gfx;

public class Config {
  private String filePath;
  private File file;
  private String[] data;

  public int canvasWidth = 800;
  public int canvasHeight = 600;
  public float canvasScalar = 1.0;

  public boolean display = true;
  public int windowWidth = 800;
  public int windowHeight = 600; 
  public int log = 1;

  public boolean invert = false;

  public boolean selectInput = false;
  public String inputImage;
  public String outputImage;
  public String outputSVG;

  public int centroidsPerPass = 500;
  public int testsPerFrame = 90000; //
  public int maxGenerations = 5; //number of generations

  public float minDotSize = 1.25;  //2;
  public float maxDotSize;
  public float dotSizeFactor = 4;  //5;

  public int maxParticles = 2000;   // Max value is normally 10000.
  public float cutoff =  0;  // White cutoff value
  public int optimize = 1000;

  public boolean gammaCorrection = false;
  public float gamma = 1.0;
  
  public boolean fill = false;
  public float fillAngle = 45.0;
  public boolean fillRandom = false;
  public boolean dot = false;
  public float line = 1.0;

  public String mode = "stipple"; //tsp

  public Config (String inputFile) {
    int index;
    String[] parts;
    file = new File(inputFile);
    filePath = file.getAbsolutePath();
    boolean exists = file.isFile();

    filePath = file.getAbsolutePath();
    exists = file.isFile();

    index = argIndex("--config");
    if (index == -1) {
      index = argIndex("-c");
    }

    if (index > -1) {
      file = new File(args[index + 1]);
      filePath = file.getAbsolutePath();
      exists = file.isFile();
    }

    if (exists) {
      println("Using config " + filePath);
      file = new File(filePath);
      data = loadStrings(filePath);
    }

    if (data != null) {
      for (int i = 0; i < data.length; i++) {
        parts = splitTokens(data[i], "=");
        setVar(parts[0], parts[1], filePath);
      }
    }

    if (args != null) {
      for (int i = 0; i < args.length; i+=2) {
        if (args[i].startsWith("--")) {
          setVar(args[i].substring(2), args[i+1], "args");
        } else {
          setVar(args[i], args[i+1], "args");
        }
      }
    }
  }

  private int argIndex (String arg) {
    int index = -1;
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        if ( args[i].startsWith(arg) ) {
          index = i;
        }
      }
    }
    return index;
  }

  private int intOrDie (String name, String val) {
    int intVal = -1;
    try {
      intVal = parseInt(val);
    } catch (Exception e) {
      println("Error parsing value " + name);
      println(e.toString());
      exit();
    }
    return intVal;
  }

  private boolean boolOrDie (String name, String val) {
    String[] truthy = { "true", "on", "t" };
    String[] falsey = { "false", "off", "f" };
    boolean boolVal = true;
    String compare = val.trim().toLowerCase();
    for (int i = 0; i < truthy.length; i++) {
      if (truthy[i].equals(compare)) {
        boolVal = true;
        break;
      }
    }
    for (int i = 0; i < falsey.length; i++) {
      if (falsey[i].equals(compare)) {
        boolVal = false;
        break;
      }
    }
    return boolVal;
  }

  private float floatOrDie (String name, String val) {
    float floatVal = -1.0;
    try {
      floatVal = parseFloat(val);
    } catch (Exception e) {
      println("Error parsing value " + name);
      println(e.toString());
      exit();
    }
    return floatVal;
  }

  private String strOrDie (String name, String val) {
    return val.trim();
  }

  public void setVar (String name, String val, String source) {
    switch (name) {
      case "canvasWidth" :
        canvasWidth = intOrDie(name, val);
        break;
      case "canvasHeight" :
        canvasHeight = intOrDie(name, val);
        break;
      case "canvasScalar" :
        canvasScalar = floatOrDie(name, val);
        break;
      case "display" :
        display = boolOrDie(name, val);
        break;
      case "windowWidth" :
        windowWidth = intOrDie(name, val);
        break;
      case "windowHeight" :
        windowHeight = intOrDie(name, val);
        break;
      case "invert" :
        invert = boolOrDie(name, val);
        break;
      case "inputImage" :
        inputImage = strOrDie(name, val);
        break;
      case "outputImage" :
        outputImage = strOrDie(name, val);
        break;
      case "outputSVG" :
        outputSVG = strOrDie(name, val);
        break;
      case "centroidsPerPass" :
        centroidsPerPass = intOrDie(name, val);
        break;
      case "testsPerFrame" :
        testsPerFrame = intOrDie(name, val);
        break;
      case "maxGenerations" :
        maxGenerations = intOrDie(name, val);
        break;
      case "minDotSize" :
        minDotSize = floatOrDie(name, val);
        break;
      case "maxDotSize" :
        maxDotSize = floatOrDie(name, val);
        break;
      case "dotSizeFactor" :
        dotSizeFactor = floatOrDie(name, val);
        break;
      case "maxParticles" :
        maxParticles = intOrDie(name, val);
        break;
      case "cutoff" :
        cutoff = intOrDie(name, val);
        break;
      case "gammaCorrection" :
        gammaCorrection = boolOrDie(name, val);
        break;
      case "gamma" :
        gamma = floatOrDie(name, val);
      case "fill" :
        fill = boolOrDie(name, val);
        break;
      case "fillAngle" :
        fillAngle = floatOrDie(name, val);
        break;
      case "fillRandom" :
        fillRandom = boolOrDie(name, val);
        break;
      case "dot" :
        dot = boolOrDie(name, val);
        break;
      case "line" :
        line = floatOrDie(name, val);
        break;
      case "mode" :
        mode = strOrDie(name, val);
        break;
      case "optimize" :
        optimize = intOrDie(name, val);
        break;
      case "log" :
        log = intOrDie(name, val);
        break;
    }
    if (log > 0) {
      println("[" + source + "] " + name + "=" + val);
    }
  }
}

public class Logger {
  private int level = 1;
  public Logger (int logLevel) {
    level = logLevel;
  }

  public void info (String line) {
    if (level > 0) {
      println(line);
    }
  }

  public void debug (String line) {
    if (level > 1) {
      println("DEBUG: " + line);
    }
  }

  public void error (String line) {
    println("ERROR: " + line);
  }

  public void setLevel (int logLevel) {
    level = logLevel;
  }
}

Logger log = new Logger(1);
Config config;

final float ACCY    = 1E-9f;

int cellBuffer = 100;  //Scale each cell to fit in a cellBuffer-sized square window for computing the centroid.
int borderWidth = 6;

float imageRatio;
float mainRatio;
float windowRatio;

float lowBorderX;
float hiBorderX;
float lowBorderY;
float hiBorderY;

boolean ReInitiallizeArray; 
boolean fileLoaded;
int SaveNow;
String[] FileOutput; 

String StatusDisplay = "Initializing, please wait. :)";
String lastStatusDisplay = "";
float millisLastFrame = 0;
float frameTime = 0;

String ErrorDisplay = "";
float ErrorTime;
Boolean ErrorDisp = false;

int Generation; 
int lastGeneration = 0;
int particleRouteLength;
int RouteStep; 

boolean showBG;
boolean showPath;
boolean showCells; 

boolean TempShowCells;
boolean FileModeTSP = false;

int vorPointsAdded;
boolean VoronoiCalculated;

// Toxic libs library setup:
Voronoi voronoi; 
Polygon2D RegionList[];

PolygonClipper2D clip;  // polygon clipper

int cellsTotal, cellsCalculated, cellsCalculatedLast;

PImage img, imgload, imgblur; 
PGraphics canvas;

Vec2D[] particles;
int[] particleRoute;

String[] header = {"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><!-- Created for Inkscape (http://www.inkscape.org/) --><svg   xmlns:dc=\"http://purl.org/dc/elements/1.1/\"   xmlns:cc=\"http://creativecommons.org/ns#\"   xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"   xmlns:svg=\"http://www.w3.org/2000/svg\"   xmlns=\"http://www.w3.org/2000/svg\"   xmlns:sodipodi=\"http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd\"   xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\"   width=\"{{WIDTH}}\"   height=\"{{HEIGHT}}\"   id=\"svg2985\"   version=\"1.1\"   inkscape:version=\"0.48.1 r9760\">  <defs     id=\"defs2987\" />  <sodipodi:namedview     id=\"base\"     pagecolor=\"#ffffff\"     bordercolor=\"#666666\"     borderopacity=\"1.0\"     inkscape:pageopacity=\"0.0\"     inkscape:pageshadow=\"2\"     inkscape:zoom=\"0.35\"     inkscape:cx=\"0\"     inkscape:cy=\"0\"     inkscape:document-units=\"px\"     inkscape:current-layer=\"layer1\"     showgrid=\"false\"  />  <metadata     id=\"metadata2990\">    <rdf:RDF>      <cc:Work         rdf:about=\"\">        <dc:format>image/svg+xml</dc:format>        <dc:type           rdf:resource=\"http://purl.org/dc/dcmitype/StillImage\" />        <dc:title />      </cc:Work>    </rdf:RDF>  </metadata>  <g     inkscape:label=\"Layer 1\"     inkscape:groupmode=\"layer\"     id=\"layer1\">      <g>"};

void LoadImageAndScale() {
  int tempx = 0;
  int tempy = 0;

  img = createImage(config.canvasWidth, config.canvasHeight, RGB);
  imgblur = createImage(config.canvasWidth, config.canvasHeight, RGB);

  img.loadPixels();

  if (config.invert) {
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(0);
    }
  } else {
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(255);
    }
  }

  img.updatePixels();

  if (config.inputImage != null) {
    imgload = loadImage(config.inputImage);
    fileLoaded = true;
  }

  if (config.display && config.selectInput && config.inputImage == null && !fileLoaded ) {
    noLoop();
    LOAD_FILE();
    return;
  }
  if ( fileLoaded == false) {
    // Load a demo image, at least until we have a "real" image to work with.
    imgload = loadImage("grace.jpg"); // Load demo image
  }

  imageRatio = (float) imgload.width / (float) imgload.height;
  mainRatio = (float) config.canvasWidth / (float) config.canvasHeight;
  windowRatio = (float) config.windowWidth / (float) config.windowHeight;

  log.info("Image: " + imgload.width + "x" + imgload.height);
  log.info("Ratio: " + imageRatio);
  log.info("Main : " + config.canvasWidth + "x" + config.canvasHeight);
  log.info("Ratio: " + mainRatio);

  //resize the image to fit within canvas size
  if ((imgload.width > config.canvasWidth) || (imgload.height > config.canvasHeight)) {
    if (imageRatio > mainRatio) { 
      imgload.resize(config.canvasWidth, 0);
    } else { 
      imgload.resize(0, config.canvasHeight);
    }
  } 

  if  (imgload.height < (config.canvasHeight - 2) ) { 
    tempy = (int) (( config.canvasHeight - imgload.height ) / 2) ;
  }
  if (imgload.width < (config.canvasWidth - 2)) {
    tempx = (int) (( config.canvasWidth - imgload.width ) / 2) ;
  }

  img.copy(imgload, 0, 0, imgload.width, imgload.height, tempx, tempy, imgload.width, imgload.height);

  //if (config.invert) {
  //  img.filter(INVERT);
  //} 

  if (config.gammaCorrection) {
    // Optional gamma correction for background image.  
    img.loadPixels();
   
    float tempFloat;  // Normally in the range 0.25 - 4.0
   
    for (int i = 0; i < img.pixels.length; i++) {
      tempFloat = brightness(img.pixels[i]) / 255;  
      img.pixels[i] = color(floor(255 * pow(tempFloat, config.gamma))); 
    } 
    
    img.updatePixels();
  }

  imgblur.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  // This is a duplicate of the background image, that we will apply a blur to,
  // to reduce "high frequency" noise artifacts.

  imgblur.filter(BLUR, 1);  // Low-level blur filter to eliminate pixel-to-pixel noise artifacts.
  imgblur.loadPixels();
}

void MainArraysetup() { 
  // Main particle array initialization (to be called whenever necessary):
  LoadImageAndScale();
  // image(img, 0, 0); // SHOW BG IMG
  particles = new Vec2D[config.maxParticles];

  // Fill array by "rejection sampling"
  int  i = 0;
  while (i < config.maxParticles) {
    float fx = lowBorderX +  random(hiBorderX - lowBorderX);
    float fy = lowBorderY +  random(hiBorderY - lowBorderY);

    float p = brightness(imgblur.pixels[ floor(fy)*imgblur.width + floor(fx) ])/255; 
    // OK to use simple floor_ rounding here, because  this is a one-time operation,
    // creating the initial distribution that will be iterated.

    if (config.invert) {
      p =  1 - p;
    }

    if (random(1) >= p ) {  
      Vec2D p1 = new Vec2D(fx, fy);
      particles[i] = p1;  
      i++;
    }
  } 

  particleRouteLength = 0;
  Generation = 0; 
  millisLastFrame = millis();
  RouteStep = 0; 
  VoronoiCalculated = false;
  cellsCalculated = 0;
  vorPointsAdded = 0;
  voronoi = new Voronoi();  // Erase mesh
  TempShowCells = true;
} 

void settings () {
  config = new Config(sketchPath() + "/config.txt");
  log.setLevel(config.log);
  if (config.display == true) {
    size(config.windowWidth, config.windowHeight, JAVA2D);
  }
}

void setup () {
  if (!config.display) {
    surface.setVisible(false);
  }
  canvas = createGraphics(config.canvasWidth, config.canvasHeight, JAVA2D);
  gfx = new ToxiclibsSupport(this, canvas);

  lowBorderX =  borderWidth; //config.canvasWidth*0.01; 
  hiBorderX = config.canvasWidth - borderWidth; //config.canvasWidth*0.98;
  lowBorderY = borderWidth; // config.canvasHeight*0.01;
  hiBorderY = config.canvasHeight - borderWidth;  //config.canvasHeight*0.98;

  int innerWidth = config.canvasWidth - 2  * borderWidth;
  int innerHeight = config.canvasHeight - 2  * borderWidth;

  clip = new SutherlandHodgemanClipper(new Rect(lowBorderX, lowBorderY, innerWidth, innerHeight));

  MainArraysetup();   // Main particle array setup

  config.maxDotSize = config.minDotSize * (1 + config.dotSizeFactor); //best way to do this?

  ReInitiallizeArray = false;
  showBG  = false;
  showPath = true;
  showCells = false;
  fileLoaded = false;
  SaveNow = 0;
  if (config.mode.equals("tsp") || config.mode.equals("TSP")) {
    FileModeTSP = true;
    log.info("Using TSP mode");
  }

  background(0); 
}

/***
 * Callback for selectInput() in LOAD_FILE.
 * Loads file if filetype is acceptable. 
 ***/
void fileSelected (File selection) {
  String[] acceptedExt = { "GIF", "JPG", "JPEG", "TGA", "PNG" };
  String[] parts;
  String loadPath;
  boolean fileOK = false;
  
  if (selection == null) {
    log.info("Window was closed or the user hit cancel.");
  } else {
    loadPath = selection.getAbsolutePath();
    log.debug("User selected " + loadPath);

    // If a file was selected, print path to file 
    log.info("Loaded file: " + loadPath); 

    parts = splitTokens(loadPath, ".");

    for (int i = 0; i < acceptedExt.length; i++) {
      if ( parts[parts.length - 1].toUpperCase().equals(acceptedExt[i])) {
        fileOK = true;
        break;
      }
    }

    log.info("File OK: " + fileOK); 

    if (fileOK) {
      imgload = loadImage(loadPath); 
      fileLoaded = true;
      // MainArraysetup();
      ReInitiallizeArray = true;
    } else {
      // Can't load file
      ErrorDisplay = "ERROR: BAD FILE TYPE";
      ErrorTime = millis();
      ErrorDisp = true;
    }
  }
  LoadImageAndScale();
  loop();
}

void LOAD_FILE () {  
  log.info(":::LOAD JPG, GIF or PNG FILE:::");
  selectInput("Select a file to process:", "fileSelected");  // Opens file chooser
}

void SAVE_PATH() {  
  FileModeTSP = true;
  SAVE_SVG();
}

void SAVE_STIPPLES () {  
  FileModeTSP = false;
  SAVE_SVG();
}

void SaveFileSelected (File selection) {
  if (selection == null) {
    // If a file was not selected
    log.info("No output file was selected...");
    ErrorDisplay = "ERROR: NO FILE NAME CHOSEN.";
    ErrorTime = millis();
    ErrorDisp = true;
    exit();
  } else { 
    config.outputSVG = selection.getAbsolutePath();
    String[] p = splitTokens(config.outputSVG, ".");
    boolean fileOK = false;

    if ( p[p.length - 1].equals("SVG") ||  p[p.length - 1].equals("svg")) {
      fileOK = true;      
    }

    if (fileOK == false) {
      config.outputSVG = config.outputSVG + ".svg";
    }

    // If a file was selected, print path to folder 
    log.info("Save file: " + config.outputSVG);
    SaveNow = 1; 
    showPath  = true;

    ErrorDisplay = "SAVING FILE...";
    ErrorTime = millis();
    ErrorDisp = true;
  }
  loop();
}

void SAVE_SVG () {  
  noLoop();
  selectOutput("Output .svg file name:", "SaveFileSelected");
}

void QUIT(float theValue) { 
  exit();
}

void ORDER_ON_OFF(float theValue) {  
  if (showPath) {
    showPath  = false;
  } else {
    showPath  = true;
  }
} 

void CELLS_ON_OFF(float theValue) {  
  if (showCells) {
    showCells  = false;
  } else {
    showCells  = true;
  }
}  

void IMG_ON_OFF(float theValue) {  
  if (showBG) {
    showBG  = false;
  } else {
    showBG  = true;
  }
} 

void INVERT_IMG(float theValue) {  
  if (config.invert) {
    config.invert  = false;
  } else {
    config.invert  = true;
  }
  ReInitiallizeArray = true;
} 

void Stipples(int inValue) { 
  if (config.maxParticles != (int) inValue) {
    log.info("Update:  Stipple Count -> " + inValue); 
    ReInitiallizeArray = true;
  }
}

void Min_Dot_Size(float inValue) {
  if (config.minDotSize != inValue) {
    log.info("Update: Min_Dot_Size -> " + inValue);  
    config.minDotSize = inValue; 
    config.maxDotSize = config.minDotSize* (1 + config.dotSizeFactor);
  }
} 

void Dot_Size_Range(float inValue) {  
  if (config.dotSizeFactor != inValue) {
    log.info("Update: Dot Size Range -> " + inValue); 
    config.dotSizeFactor = inValue;
    config.maxDotSize = config.minDotSize* (1 + config.dotSizeFactor);
  }
} 

void White_Cutoff(float inValue) {
  if (config.cutoff != inValue) {
    log.info("Update: White_Cutoff -> "+inValue); 
    config.cutoff = inValue; 
    RouteStep = 0; // Reset TSP path
  }
} 

void  DoBackgrounds() {
  if (showBG) {
    canvas.image(img, 0, 0);    // Show original (cropped and scaled, but not blurred!) image in background
  } else { 
    if (config.invert) {
      canvas.background(0);
    } else {
      canvas.background(255);
    }
  }
}

void OptimizePlotPath () { 
  log.info("Optimizing plot path...");
  int temp;
  StatusDisplay = "Optimizing plotting path";
  Vec2D p1;

  if (RouteStep == 0) {
    float cutoffScaled = 1 - config.cutoff;
    // Begin process of optimizing plotting route, by flagging particles that will be shown.
    particleRouteLength = 0;

    boolean particleRouteTemp[] = new boolean[config.maxParticles]; 

    for (int i = 0; i < config.maxParticles; ++i) {
      particleRouteTemp[i] = false;

      int px = (int) particles[i].x;
      int py = (int) particles[i].y;

      if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0)) {
        continue;
      }

      float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255; 

      if (config.invert) {
        v = 1 - v;
      }

      if (v < cutoffScaled) {
        particleRouteTemp[i] = true;   
        particleRouteLength++;
      }
    }

    particleRoute = new int[particleRouteLength]; 
    int tempCounter = 0;  
    for (int i = 0; i < config.maxParticles; ++i) { 
      if (particleRouteTemp[i]) {
        particleRoute[tempCounter] = i;
        tempCounter++;
      }
    }
    // These are the ONLY points to be drawn in the tour.
  }

  if (RouteStep < (particleRouteLength - 2)) { 

    // Nearest neighbor ("Simple, Greedy") algorithm path optimization:

    int StopPoint = RouteStep + config.optimize;      // 1000 steps per frame displayed; you can edit this number!

    if (StopPoint > (particleRouteLength - 1)) {
      StopPoint = particleRouteLength - 1;
    }

    for (int i = RouteStep; i < StopPoint; ++i) { 
      p1 = particles[particleRoute[RouteStep]];
      int ClosestParticle = 0; 
      float  distMin = Float.MAX_VALUE;

      for (int j = RouteStep + 1; j < (particleRouteLength - 1); ++j) { 
        Vec2D p2 = particles[particleRoute[j]];

        float  dx = p1.x - p2.x;
        float  dy = p1.y - p2.y;
        float  distance = (float) (dx*dx+dy*dy);  // Only looking for closest; do not need sqrt factor!

        if (distance < distMin) {
          ClosestParticle = j; 
          distMin = distance;
        }
      }  

      temp = particleRoute[RouteStep + 1];
      //        p1 = particles[particleRoute[RouteStep + 1]];
      particleRoute[RouteStep + 1] = particleRoute[ClosestParticle];
      particleRoute[ClosestParticle] = temp;

      if (RouteStep < (particleRouteLength - 1)) {
        RouteStep++;
      } else {
        log.info("Now optimizing plot path" );
      }
    }
  } else {     
    // Initial routing is complete
    // 2-opt heuristic optimization:
    // Identify a pair of edges that would become shorter by reversing part of the tour.

    for (int i = 0; i < config.testsPerFrame; i++) {   
      int indexA = floor(random(particleRouteLength - 1));
      int indexB = floor(random(particleRouteLength - 1));

      if (Math.abs(indexA  - indexB) < 2) {
        continue;
      }

      if (indexB < indexA) {  
        // swap A, B.
        temp = indexB;
        indexB = indexA;
        indexA = temp;
      }

      Vec2D a0 = particles[particleRoute[indexA]];
      Vec2D a1 = particles[particleRoute[indexA + 1]];
      Vec2D b0 = particles[particleRoute[indexB]];
      Vec2D b1 = particles[particleRoute[indexB + 1]];

      // Original distance:
      float  dx = a0.x - a1.x;
      float  dy = a0.y - a1.y;
      float  distance = (float) (dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 
      dx = b0.x - b1.x;
      dy = b0.y - b1.y;
      distance += (float) (dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 

      // Possible shorter distance?
      dx = a0.x - b0.x;
      dy = a0.y - b0.y;
      float distance2 = (float) (dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 
      dx = a1.x - b1.x;
      dy = a1.y - b1.y;
      distance2 += (float) (dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 

      if (distance2 < distance) {
        // Reverse tour between a1 and b0.   
        int indexhigh = indexB;
        int indexlow = indexA + 1;

        while (indexhigh > indexlow) {
          temp = particleRoute[indexlow];
          particleRoute[indexlow] = particleRoute[indexhigh];
          particleRoute[indexhigh] = temp;

          indexhigh--;
          indexlow++;
        }
      }
    }
  }

  frameTime = (millis() - millisLastFrame) / 1000;
  millisLastFrame = millis();
}

void doPhysics() {   
  // Iterative relaxation via weighted Lloyd's algorithm.
  int temp;
  int CountTemp;

  if (VoronoiCalculated == false){  
    // Part I: Calculate voronoi cell diagram of the points.

    StatusDisplay = "Calculating Voronoi diagram "; 

    //    float millisBaseline = millis();  // Baseline for timing studies
    //    log.info("Baseline.  Time = " + (millis() - millisBaseline) );

    if (vorPointsAdded == 0) {
      voronoi = new Voronoi();  // Erase mesh
    }

    temp = vorPointsAdded + 500;   // This line: VoronoiPointsPerPass  (Feel free to edit this number.)
    if (temp > config.maxParticles) {
      temp = config.maxParticles; 
    }

    for (int i = vorPointsAdded; i < temp; i++) {  
      // Optional, for diagnostics:::
      try {
        voronoi.addPoint(new Vec2D(particles[i].x, particles[i].y ));
      } catch (Exception e) {
        continue;
      }
      vorPointsAdded++;
    }   

    if (vorPointsAdded >= config.maxParticles) {
      //    log.info("Points added.  Time = " + (millis() - millisBaseline) );
      cellsTotal =  (voronoi.getRegions().size());
      vorPointsAdded = 0;
      cellsCalculated = 0;
      cellsCalculatedLast = 0;

      RegionList = new Polygon2D[cellsTotal];

      int i = 0;
      for (Polygon2D poly : voronoi.getRegions()) {
        RegionList[i++] = poly;  // Build array of polygons
      }
      VoronoiCalculated = true;
    }
  } else{    
  // Part II: Calculate weighted centroids of cells.
    //  float millisBaseline = millis();
    log.debug("fps = " + frameRate );

    StatusDisplay = "Calculating weighted centroids"; 

    // This line: CentroidsPerPass  (Feel free to edit this number.)
    // Higher values give slightly faster computation, but a less responsive GUI.
    // Default value: 500
    temp = cellsCalculated + config.centroidsPerPass;   

    if (temp > cellsTotal) {
      temp = cellsTotal;
    }

    for (int i=cellsCalculated; i< temp; i++) {  
      float xMax = 0;
      float xMin = config.canvasWidth;
      float yMax = 0;
      float yMin = config.canvasHeight;
      float xt, yt;

      Polygon2D region = clip.clipPolygon(RegionList[i]);

      for (Vec2D v : region.vertices) { 
        xt = v.x;
        yt = v.y;

        if (xt < xMin) {
          xMin = xt;
        }
        if (xt > xMax) {
          xMax = xt;
        }
        if (yt < yMin) {
          yMin = yt;
        }
        if (yt > yMax) {
          yMax = yt;
        }
      }
 
      float xDiff = xMax - xMin;
      float yDiff = yMax - yMin;
      float maxSize = max(xDiff, yDiff);
      float minSize = min(xDiff, yDiff);

      float scaleFactor = 1.0;

      // Maximum voronoi cell extent should be between
      // cellBuffer/2 and cellBuffer in size.

      while (maxSize > cellBuffer) {
        scaleFactor *= 0.5;
        maxSize *= 0.5;
      }

      while (maxSize < (cellBuffer/2)) {
        scaleFactor *= 2;
        maxSize *= 2;
      }  

      if ((minSize * scaleFactor) > (cellBuffer/2)) {
        // Special correction for objects of near-unity (square-like) aspect ratio, 
        // which have larger area *and* where it is less essential to find the exact centroid:
        scaleFactor *= 0.5;
      }

      float StepSize = (1/scaleFactor);

      float xSum = 0;
      float ySum = 0;
      float dSum = 0;       
      float PicDensity = 1.0; 

      if (config.invert) {
        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {

            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) { 

              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.  
              PicDensity = 0.001 + (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));  

              xSum += PicDensity * x;
              ySum += PicDensity * y; 
              dSum += PicDensity;
            }
          }
        }  
      } else {
        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {
            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) {
              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur. 
              PicDensity = 255.001 - (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));  


              xSum += PicDensity * x;
              ySum += PicDensity * y; 
              dSum += PicDensity;
            }
          }
        }  
      }
      if (dSum > 0) {
        xSum /= dSum;
        ySum /= dSum;
      }

      Vec2D centr;

      float xTemp  = (xSum);
      float yTemp  = (ySum);

      if ((xTemp <= lowBorderX) || (xTemp >= hiBorderX) || (yTemp <= lowBorderY) || (yTemp >= hiBorderY)) {
        // If new centroid is computed to be outside the visible region, use the geometric centroid instead.
        // This will help to prevent runaway points due to numerical artifacts. 
        centr = region.getCentroid(); 
        xTemp = centr.x;
        yTemp = centr.y;

        // Enforce sides, if absolutely necessary:  (Failure to do so *will* cause a crash, eventually.)
        if (xTemp <= lowBorderX) {
          xTemp = lowBorderX + 1; 
        }
        if (xTemp >= hiBorderX) {
          xTemp = hiBorderX - 1; 
        }
        if (yTemp <= lowBorderY) {
          yTemp = lowBorderY + 1; 
        }
        if (yTemp >= hiBorderY) {
          yTemp = hiBorderY - 1;
        }
      }      

      particles[i].x = xTemp;
      particles[i].y = yTemp;

      cellsCalculated++;
    } 
    log.debug("cellsCalculated = " + cellsCalculated );
    log.debug("cellsTotal = " + cellsTotal );

    if (cellsCalculated >= cellsTotal) {
      VoronoiCalculated = false; 
      Generation++;
      frameTime = (millis() - millisLastFrame)/1000;
      millisLastFrame = millis();
    }
  }
}

/**
 * https://forum.processing.org/two/discussion/3506/point-on-an-outer-circle-intercepted-by-a-line-perpendicular-to-the-tangent-of-an-inner-circle
 * Calculate the points of intersection between a line and the
 * circumference of a circle.
 * [x0, y0] - [x1, y1] the line end coordinates 
 * [cx, cy] the centre of the circle
 * r the radius of the circle
 *
 * An array is returned that contains the intersection points in x, y order.
 * If the returned array is of length: 
 * 0 then there is no intersection 
 * 2 there is just one intersection (the line is a tangent to the circle) 
 * 4 there are two intersections 
 */
public float[] line_circle_p(float x0, float y0, float x1, float y1, float cx, float cy, float r) {
  float[] result = null;
  float f = (x1 - x0);
  float g = (y1 - y0);
  float fSQ = f*f;
  float gSQ = g*g;
  float fgSQ = fSQ + gSQ;
 
  float xc0 = cx - x0;
  float yc0 = cy - y0;
 
  float fygx = f*yc0 - g*xc0;
  float root = r*r*fgSQ - fygx*fygx;
  if (root > -ACCY) {
    float[] temp = null;
    int np = 0;
    float fxgy = f*xc0 + g*yc0;
    if (root < ACCY) {    // tangent so just one point
      float t = fxgy / fgSQ;
      temp = new float[] { 
        x0 + f*t, y0 + g*t
      };
      np = 2;
    }
    else {  // possibly two intersections
      temp = new float[4];
      root = sqrt(root);
      float t = (fxgy - root)/fgSQ;
      //     if (t >= 0 && t <= 1) {
      temp[np++] = x0 + f*t;
      temp[np++] = y0 + g*t;
      t = (fxgy + root)/fgSQ;
      temp[np++] = x0 + f*t;
      temp[np++] = y0 + g*t;
    }
    if (temp != null) {
      result = new float[np];
      System.arraycopy(temp, 0, result, 0, np);
    }
  }
  return (result == null) ? new float[0] : result;
}

/**
 * Create hatch lines within a circle determined by a line width
 *
 * x {float} center of circle on x axis
 * y {float} center of circle on y axis
 * d {float} diameter of circle
 * angle {float} angle of hatching, 0-360
 * line {float} width of line
 **/
ArrayList<float[]> fillCircle (float x, float y, float d, float angle, float line) {
  ArrayList<float[]> output = new ArrayList<float[]>();
  float r = (d / 2.0);
  float perpAngle = (angle + 90.0) % 360.0;
  float perpRadian = radians(perpAngle);
  float radian = radians(angle);
  int lines = floor(d / line);
  float perpX = 0;
  float perpY = 0;
  float startX = 0;
  float startY = 0;
  float endX = 0;
  float endY = 0;
  float testX = 0;
  float testY = 0;
  float[] intersect;

  for (int i = -lines; i < lines; i++) {
    perpX = x + ( ( (line / 2) * (i + 0.5) ) * cos(perpRadian));
    perpY = y + ( ( (line / 2) * (i + 0.5) ) * sin(perpRadian));
    testX = perpX + (d * cos(radian));
    testY = perpY + (d * sin(radian));
    
    intersect = line_circle_p(perpX, perpY, testX, testY, x, y, r);

    if (intersect.length > 0) {
      startX = intersect[0];
      startY = intersect[1];
    } else {
      continue;
    }
    
    testX = startX - (d * cos(radian));
    testY = startY - (d * sin(radian));

    intersect = line_circle_p(perpX, perpY, testX, testY, x, y, r);

    if (intersect.length > 0) {
      endX = intersect[0];
      endY = intersect[1];
    } else {
      continue;
    }

    if (dist(startX, startY, endX, endY) > line) {
      float[] linePoints = { startX, startY, endX, endY };
      output.add(linePoints);
    }
  }
  return output;
}

void draw () {
  int i = 0;
  int temp;
  int scaledDimension;
  float dotScale = (config.maxDotSize - config.minDotSize);
  float dotRad;
  float dotDiam;
  float cutoffScaled = 1 - config.cutoff;
  float hatchAngle;
  ArrayList<float[]> hatchLines;

  canvas.beginDraw();
  canvas.smooth();
  canvas.noStroke();


  if (ReInitiallizeArray) {
    MainArraysetup();
    ReInitiallizeArray = false;
  } 

  doPhysics();

  if ( showPath ) {
    canvas.stroke(128, 128, 255);   // Stroke color (blue)
    canvas.strokeWeight (1);

    for ( i = 0; i < (particleRouteLength - 1); ++i) {
      Vec2D p1 = particles[particleRoute[i]];
      Vec2D p2 = particles[particleRoute[i + 1]];

      canvas.line(p1.x, p1.y, p2.x, p2.y);
    }
  }

  if (config.invert) {
    canvas.stroke(255);
  } else {
    canvas.stroke(0);
  }

  // NOT in pause mode.  i.e., just displaying stipples.
  if (cellsCalculated == 0) {

    DoBackgrounds();

    if (Generation == 0) {
      TempShowCells = true;
    }

    if (showCells || TempShowCells) {  // Draw voronoi cells, over background.
      canvas.strokeWeight(1);
      canvas.noFill();

      if (config.invert && (showBG == false)) {  // TODO -- if config.invert AND NOT background
        canvas.stroke(100);
      } else {
        canvas.stroke(200);
      }
      //        stroke(200);

      i = 0;
      for (Polygon2D poly : voronoi.getRegions()) {
        //RegionList[i++] = poly; 
        gfx.polygon2D(clip.clipPolygon(poly));
      }
    }

    if (showCells) {
      // Show "before and after" centroids, when polygons are shown.
      // Normal w/ Min & Max dot size
      strokeWeight(config.minDotSize);  
      for ( i = 0; i < config.maxParticles; ++i) {

        int px = (int) particles[i].x;
        int py = (int) particles[i].y;

        if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0)) {
          continue;
        }
        //Uncomment the following four lines, if you wish to display the "before" dots at weighted sizes.
        //float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255;  
        //if (config.invert)
        //v = 1 - v;
        //strokeWeight (config.maxDotSize - v * dotScale);  
        canvas.point(px, py);
      }
    }
  } else {
    // Stipple calculation is still underway
    if (TempShowCells) {
      DoBackgrounds(); 
      TempShowCells = false;
    }
    // stroke(0);   // Stroke color

    if (config.invert) {
      canvas.stroke(255);
    } else {
      canvas.stroke(0);
    }

    if (config.line * config.canvasScalar >= 1.0) {
      canvas.strokeWeight(config.line * config.canvasScalar);
    } else {
      canvas.strokeWeight(1.0);
    }

    if (!FileModeTSP && config.dot) {
      canvas.noStroke();
      if (config.invert) {
        canvas.fill(255);
      } else {
        canvas.fill(0);
      }
    }

    if (FileModeTSP) {
      OptimizePlotPath();
      canvas.background(config.invert ? 0 : 255);
      canvas.beginShape();
      for ( i = 0; i < particleRouteLength; ++i) {
        Vec2D p1 = particles[particleRoute[i]];  
        float xTemp = p1.x;
        float yTemp = p1.y;        
        canvas.vertex(xTemp,  yTemp);
      } 
      canvas.endShape();
    } else {
      for ( i = cellsCalculatedLast; i < cellsCalculated; i++) {
        int px = (int) particles[i].x;
        int py = (int) particles[i].y;

        if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0)) {
          continue;
        }
        
        float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255; 

        if (config.invert) {
          v = 1 - v;
        }

        if (v < cutoffScaled) { 
          dotDiam = (config.maxDotSize - v * dotScale) * config.canvasScalar;
          if (dotDiam < config.minDotSize) {
            dotDiam = config.minDotSize;
          }
          canvas.ellipse(px, py, dotDiam, dotDiam);
          if (!config.dot && config.fill) {
            hatchAngle = config.fillRandom ? random(0.0, 360.0) : config.fillAngle;
            hatchLines = fillCircle(px, py, dotDiam, hatchAngle, config.line * config.canvasScalar);
            if (hatchLines.size() > 0) {
              for (float[] linePoints : hatchLines) {
                canvas.line(linePoints[0], linePoints[1], linePoints[2], linePoints[3]);
              }
            }
          }
        }
      }
      cellsCalculatedLast = cellsCalculated;
    }
  }

  canvas.endDraw();

  if (config.display) {
    if (mainRatio >= windowRatio) {
      scaledDimension = round((float) height * mainRatio);
      image(canvas, (width - scaledDimension) / 2, 0, scaledDimension, height);
    } else {
      scaledDimension = round((float) width / mainRatio);
      image(canvas, 0, (height - scaledDimension) / 2, width, scaledDimension);
    }
  } 

  if (Generation != lastGeneration) {
    if (!TempShowCells && config.outputImage != null) {
      canvas.save(config.outputImage);
    }
    log.info("Generation completed: " + Generation + " / " + config.maxGenerations ); 
    log.debug("Generation time: " + frameTime + " s");
    lastGeneration = Generation;
  }

  if (ErrorDisp) {
    log.error(ErrorDisplay);
    if ((millis() - ErrorTime) > 8000) {
      ErrorDisp = false;
    }
  } else {
    if (!lastStatusDisplay.equals(StatusDisplay)) {
      log.debug(StatusDisplay);
      lastStatusDisplay = StatusDisplay;
    }
  }

  if (Generation == config.maxGenerations) {
    SaveNow = 1;
  }

  if (SaveNow > 0 && config.display && config.outputSVG == null) {
    SAVE_SVG();
    return;
  }

  if (SaveNow > 0 && config.outputSVG != null) {
    if (!FileModeTSP) {
      OptimizePlotPath();
    }
    StatusDisplay = "Saving SVG File";
    FileOutput = header;
    String rowTemp;

    for (i = 0; i < FileOutput.length; i++) {
      FileOutput[i] = FileOutput[i].replace("{{WIDTH}}", str(config.canvasWidth));
      FileOutput[i] = FileOutput[i].replace("{{HEIGHT}}", str(config.canvasHeight));
    }

    //Need to get some background on this.
    //what are these magic numbers?
    float SVGscale = 1.0; //(800.0 / (float) config.canvasHeight); 
    //not centering the image is more controllable
    int xOffset = 0; //(int) (1536 - (SVGscale * config.canvasWidth / 2)); 
    int yOffset = 0; //(int) (1056  - (SVGscale * config.canvasHeight / 2));

    if (FileModeTSP) { 
      // Plot the PATH between the points only.
      log.info("Saving TSP File (SVG)");
      log.info(config.outputSVG);
      // Path header::
      rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:"+ config.line +";stroke-linejoin:round;stroke-linecap:round;\" d=\"M "; 
      FileOutput = append(FileOutput, rowTemp);

      for ( i = 0; i < particleRouteLength; ++i) {

        Vec2D p1 = particles[particleRoute[i]];  

        float xTemp = SVGscale * p1.x + xOffset;
        float yTemp = SVGscale * p1.y + yOffset;        

        if (i == 0) {
          rowTemp = xTemp + " " + yTemp + "\r";
        } else {
          rowTemp = "L " + xTemp + " " + yTemp + "\r";
        }

        FileOutput = append(FileOutput, rowTemp);
      } 
      FileOutput = append(FileOutput, "\" />"); // End path description
    } else {
      log.info("Saving Stipple File (SVG)");
      log.info(config.outputSVG);
      for ( i = 0; i < particleRouteLength; ++i) {

        Vec2D p1 = particles[particleRoute[i]]; 

        int px = floor(p1.x);
        int py = floor(p1.y);

        float v = (brightness(imgblur.pixels[ py*imgblur.width + px ])) / 255;  

        if (config.invert) {
          v = 1 - v;
        }

        dotRad = (config.maxDotSize - v * dotScale) / 2; 

        float xTemp = SVGscale * p1.x + xOffset;
        float yTemp = SVGscale * p1.y + yOffset; 
        
        if (config.dot) {
          rowTemp = "<path d=\"M " + xTemp + "," + yTemp + " L " + (xTemp + 0.01 ) + "," + yTemp + "\" style=\"fill:none;stroke:black;stroke-width:" + dotRad + ";\"/>";
        } else {
          rowTemp = "<circle cx=\"" + xTemp + "\" cy=\"" + yTemp + "\" r=\"" + dotRad +
          "\" style=\"fill:none;stroke:black;stroke-width:1;\"/>";
          // Typ:   <circle  cx="1600" cy="450" r="3" style="fill:none;stroke:black;stroke-width:2;"/>
        }

        if (!config.dot && config.fill) {
          hatchAngle = config.fillRandom ? random(0.0, 360.0) : config.fillAngle;
          hatchLines = fillCircle(xTemp, yTemp, dotRad * 2.0, hatchAngle, config.line);
          if (hatchLines.size() > 0) {
            for (float[] linePoints : hatchLines) {
              rowTemp += "<line x1=\"" + linePoints[0] + "\" y1=\"" + linePoints[1] + "\" x2=\"" + linePoints[2] + "\" y2=\"" + linePoints[3] + "\" style=\"fill:none;stroke:black;stroke-width:1;\"/>";
            }
          }
        }
        FileOutput = append(FileOutput, rowTemp);
      }
    }

    // SVG footer:
    FileOutput = append(FileOutput, "</g></g></svg>");
    saveStrings(config.outputSVG, FileOutput);
    //FileModeTSP = false; // reset for next time

    if (FileModeTSP) {
      ErrorDisplay = "TSP Path .SVG file Saved";
    } else {
      ErrorDisplay = "Stipple .SVG file saved ";
    }

    ErrorTime = millis();
    ErrorDisp = true;
  } else if (SaveNow > 0 && config.outputSVG == null) {
    log.info("Exiting without exporting SVG");
  }

  if (SaveNow > 0) {
    exit();
  }
} 
