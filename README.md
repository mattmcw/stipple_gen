# stipple_gen

A friendly fork of StippleGen_2 from Evil Mad Scientist Laboratories.

https://github.com/evil-mad/stipplegen

This script takes an image, provided as a JPEG, a PNG or a TIFF (generated by Processing) and outputs both an SVG for a plotter as well as a approximation as a JPEG, PNG or TIFF.

There have also been features added to do the following:

* **Custom output SVG scale**
* **Custom canvas size**
* **Option to fill in circles**

# Usage

`stipple_gen` is designed to be configured and run from the command line, rather than the GUI provided in the original sketch.
By creating a config.txt file in your sketch directory *OR* providing command line arguments to your sketch you can set all of the variables accessible to the GUI in the original StippleGen_2 sketch and then some.

An example using the helpful `stipple_gen.sh` script provided by this project.

```bash
bash stipple_gen.sh --display true --inputImage myImage.jpg --outputImage myStippledImage.jpg --outputSVG myStippledDrawing.svg
```

This will take your original image `myImage.jpg` and run it through the stippling process using the default variables for everything and output two files for you: `myStippledImage.jpg` and `myStippledDrawing.svg`, the latter of which you can use on your plotter.

Other variables: 

```java

public int canvasWidth = 800;
public int canvasHeight = 600;

public boolean display = true;
public int windowWidth = 800;
public int windowHeight = 600; 

public boolean invert = false;

public boolean selectInput = false;
public String inputImage;
public String outputImage;
public String outputSVG;

public int centroidsPerPass = 500;
public int testsPerFrame = 90000; //
public int maxGenerations = 5; //number of generations

public float MinDotSize = 1.25;  //2;
public float MaxDotSize;
public float DotSizeFactor = 4;  //5;

public int maxParticles = 2000;   // Max value is normally 10000.
public float cutoff =  0;  // White cutoff value

public boolean gammaCorrection = false;
public float gamma = 1.0;

```