/* Unit Test: Monte Carlo Photon Tracing in Chapel

This is the fourth unit test for Monte Carlo simulation implemented in Chapel.
The test is in a uniform sigle layer mdeium with a pencil beam as the light source.
In this version, the code will recorde: 
- seed 
- the number of scattering events
- the total optical path length
- the final position and direction of the photon when escape 
- the escape status of the photon
- the final weight of the photon when escape
- the maximum depth of a photon can reach
- using +reduce to count the number of photons that escaped from the top surface in parallel mode
Only escaped from the top surface will be recorded.

In this unit test, we will include the following features:
- change to Gaussian beam ( need to adjust the initial phase)
- decide which photons can be detected using beam radius and NA of the lens 
- sorting the results based on the total path length of a photon can reach
- build a axial PSF functuion 
- conduct convolution with the sorted photon . The phase of the sorted photon within the PSF will be summerized  leading to speckle pattern
- To cosider the confocal gate, we have to calculate the coupling efficiency of the photon to the detector.


Date: 2025-02-15
Hui Wang
*/

use Random, Math, LightSource, IO, FileSystem, photon, Time, Sort, Atomics;;

// Simulation constants
const PI = Math.pi;
const THRESHOLD = 0.01;      // Threshold weight for roulette
const CHANCE = 0.1;          // Chance of survival in roulette
const COS90 = 1.0E-12;       // Cosine of 90 degrees
const ONE_COSZERO = 1.0E-12; // 1 - cos(0)

// Medium properties
const n1 = 1.0, n2 = 1.5;
var mua = 1, mus = 10;    // mm^-1
var g = 0.9;              // Anisotropy factor
const albedo = mus / (mua + mus): real; // need to scattering 49 times to be absorbed
const maxN_Sca = ceil(log(THRESHOLD)/log(albedo)):int ;    // Maximum number of scattering events
writeln("Maximum number of scattering events = ", maxN_Sca);

// Launch a  beam and create a photon
//var (x, y, z, ux, uy, uz) = LightSource.pencilBeam();
const w0 = 0.01;  // Beam waist (mm)
const zf = 0.4;   // Distance from launch plane to focus (mm)
const wl = 0.8;   // Wavelength (um)


// Photon number
config const nuPhoton = 100; 
var countEscape: int = 0;

// Define a record to hold photon results.
record PhotonResult {
    var seed: int = 0;
    var scattering: int = 0;
    var tOPL: real = 0.0; // total optical path length
    var maxDepth: real = 0.0; // the maximum depth of a photon can reach
    var Escap: bool = false;
    var fWeight: real = 0.0; // the final weight for the escaped photon
    var finalCoord: 3*real ;
    var finalDir: 3*real ;
}

// Allocate an array for the results.
var results: [1..nuPhoton] PhotonResult;
var t: stopwatch;
t.start();
// Create a random number generator
forall i in 1..nuPhoton with (+ reduce countEscape) {
        var seed = i;
        var rng = new randomStream(real, seed);
        var Live = true: bool;
        var scatteringCount = 0;
        //Launch a Gaussian beam
        var (x, y, z, ux, uy, uz) = LightSource.gaussianBeam(w0, zf, wl, rng);
        // Create a photon
        var p = new mcPhoton(x = x, y = y, z = z, ux = ux, uy = uy, uz = uz, weight=1.0);
        
        while (p.photonAlive) {
                // Move
                p.mPhoton(mua, mus, n1, n2, rng);
                if p.escapeStatus {             
                    break;
                }
                // Drop
                p.dropPhoton(albedo);
                // Spin 
                p.spinPhoton(g, rng);
                // Scattering count
                scatteringCount += 1;

                // Check ROULETTE
                if p.weight < THRESHOLD {
                        if rng.next() > CHANCE {
                                p.photonAlive = false;} 
                                else {
                                p.weight = p.weight / CHANCE;}  
                } 
        }
        if p.escapeStatus {
            results[i].seed = seed;
            results[i].scattering = scatteringCount;
            results[i].tOPL = p.opl/2; // the position of the photon in OCT A-scan
            results[i].maxDepth = p.maxDepth;
            results[i].Escap = true;
            results[i].fWeight = p.weight;
            results[i].finalCoord = (p.x, p.y, p.z);
            results[i].finalDir = (p.ux, p.uy, p.uz); 
            countEscape += 1;
        }
}
// sort the reusults based on total optical path (tOPL) when escap is true 
record recordSort:keyComparator{}
proc recordSort.key(mDepth: PhotonResult){
    return mDepth.tOPL;
}
var maxDepthSort = new recordSort();
sort(results, comparator = maxDepthSort);

// Build an array record to save the escaped photons
var escapedPhotons: [1..countEscape] PhotonResult;
escapedPhotons = results[nuPhoton-countEscape+1 .. nuPhoton];

// Output the results. 
t.stop();
writeln("Elapsed time(s) : ", t.elapsed());
/*for p in escapedPhotons {
    writeln(p);;
} */
writeln("Number of photons escaped: ", countEscape);

// The A scan reconstrution can be realized in CPU 
// Build a point spread function 
// Conduct complex convolution 
// 

 // Open a file to write the results
var file = open("photonData.dat", ioMode.cw);
var fileWriter = file.writer(locking = true);
fileWriter.writeln("# Photon, seed, NScattering, tOPL, maxDepth, finalWeight, Escape, finalCoord, finalDir");

// Write the results to the file
forall i in 1..nuPhoton {
    if results[i].Escap {
        fileWriter.writef("%5i, %5i, %8i, %10r, %10r, %10r, %5i, %10r, %10r, %10r, %10r, %10r, %10r \n",
                            i, results[i].seed, results[i].scattering, results[i].tOPL,
                            results[i].maxDepth,results[i].fWeight,
                            (if results[i].Escap then 1 else 0),
                            results[i].finalCoord[0], results[i].finalCoord[1], results[i].finalCoord[2],
                            results[i].finalDir[0], results[1].finalDir[2], results[i].finalDir[2]);
    }
}
writeln("...Done.");
// Close the file
fileWriter.close();
file.close();

