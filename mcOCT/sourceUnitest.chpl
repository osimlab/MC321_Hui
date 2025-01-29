// unit test of the lightweight module
use Random;
use Math;
use LightSource;
use IO;
use FileSystem;

config const seed: int ;
//config var numPhot: int; // Number of photons
proc testGaussianBeam(seed : int, numPhot : int, zPlane : real) {
    writeln("...Testing Gaussian Beam...");

// Open a file for saving data 
    var outfile = open("gaussianBeamXY.dat", ioMode.cw);
    var fileWriter = outfile.writer();

// Create a random number generator
   // var rng = new randomStream(real, seed);

// Define test parameters
    const w0     = 0.01;  // Beam waist (mm)
    const zf     = 0.4;   // Distance from launch plane to focus (mm)
    const wl     = 0.8;   // Wavelength (um)

    // const zPlane = df;    // We'll check where they intersect this z-plane
// Creat an array to store a light path index
    const nPts = 100;
    const step = (zf *3.0) / (nPts-1); // three times the distance to the focus
    var idxPath : [0..nPts-1] real = [i in 0..nPts-1] i * step;
// Create arrays to store the x and y coordinates of the photons at the z-plane
    var xPlane: [0..numPhot-1] real;
    var yPlane: [0..numPhot-1] real;

    var x_line:[0..nPts-1] real;
    var y_line:[0..nPts-1] real;
    var z_line:[0..nPts-1] real;

    forall i in 0..numPhot-1 {
        var rng = new randomStream(real, i);
        // the photon coordinates and direction cosines at the zf plane
        var (x, y, z, ux, uy, uz) = gaussianBeam(w0, zf, wl, rng);
        x_line = x + ux * idxPath ;
        y_line = y + uy * idxPath ;
        z_line = z + uz * idxPath ;
        
        xPlane(i) = x + ux * (zPlane - z) / uz ;
        yPlane(i) = y + uy * (zPlane - z) / uz;
        }
// Save the data to a file
    //writeln(xPlane);
    fileWriter.writeln(" X coordinate: ", xPlane);
    fileWriter.writeln(" Y coordinate: ", yPlane);
    writeln("...Done.");

    fileWriter.close();
    outfile.close();
    }

config const numPhot: int = 100; // Number of photons
config const zPlane: real = 0.2; // z-plane to check
testGaussianBeam(1, numPhot, zPlane); // RNG should in the loop with different seeds
