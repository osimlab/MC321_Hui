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

Note: This test is not for OCT (Optical Coherence Tomography) detection but focuses solely
on tracing the paths of photons in the simulation.

Date: 2025-02-14
Hui Wang
*/

use Random, Math, LightSource, IO, FileSystem, photon, Time;

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

// Launch a pencil beam and create a photon
var (x, y, z, ux, uy, uz) = LightSource.pencilBeam();

// Photon number
config const nuPhoton = 100; 
var countEscape: int = 0;

// Define a record to hold photon results.
record PhotonResult {
    var seed: int = 0;
    var scattering: int = 0;
    var tOPL: real = 0.0; // total optical path length
    var Escap: bool = false;
    var fWeight: real = 0.0; // the final weight for the escaped photon
    var maxDepth: real = 0.0; // the maximum depth of a photon can reach
    var finalCoord: [1..3] real = [1..3] 0.0;
    var finalDir: [1..3] real = [1..3] 0.0;
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
            results[i].tOPL = p.opl;
            results[i].maxDepth = p.maxDepth;
            results[i].Escap = true;
            results[i].fWeight = p.weight;
            results[i].finalCoord = [p.x, p.y, p.z];
            results[i].finalDir = [p.ux, p.uy, p.uz];
            countEscape += 1;

        }
}

// Output the results.
/* writeln("Number of photons escaped: ", countEscape);
for i in 1..nuPhoton {
    if results[i].Escap {
        writeln("Photon ", i, ":");
        writeln("  Seed: ", results[i].seed);
        writeln("  Scattering events: ", results[i].scattering);
        writeln("  Total optical path length: ", results[i].tOPL);
        writeln("  Maxdepth: ", results[i].maxDepth);
        writeln("  Final weight: ", results[i].fWeight);
        writeln("  Final Coordinate: ", results[i].finalCoord);
        writeln("  Final Direction: ", results[i].finalDir);
        writeln();
    }
} */
// Open a file to write the results
var file = open("photonData.dat", ioMode.cw);
var fileWriter = file.writer();
fileWriter.writeln("# Photon, seed, NScattering, tOPL, maxDepth, finalWeight, Escape, finalCoord, finalDir");

// Write the results to the file
for i in 1..nuPhoton {
    if results[i].Escap {
        fileWriter.writef("%5i, %5i, %8i, %10r, %10r, %10r, %5i, %10r, %10r, %10r, %10r, %10r, %10r \n",
                            i, results[i].seed, results[i].scattering, results[i].tOPL,
                            results[i].maxDepth,results[i].fWeight,
                            (if results[i].Escap then 1 else 0),
                            results[i].finalCoord[1], results[i].finalCoord[2], results[i].finalCoord[3],
                            results[i].finalDir[1], results[i].finalDir[2], results[i].finalDir[3]);
    }
}
writeln("...Done.");
// Close the file
fileWriter.close();
file.close();
t.stop();
writeln("Elapsed time(s) : ", t.elapsed());