/* 9/30/24: using Random; Python style*/
use IO;
use Time;
use Random;
// Define photonGenerator module with all photon related parameters
use photonGeneratorR;

// Define optical properties 
config var mua = 1.0;                /* absorption coefficient [cm^-1] */
config var mus = 20.0;               /* scattering coefficient [cm^-1] */
albedo = mus / (mus+mua);
g = 0.90;                 /* anisotropy [-] */
nt = 1.33;                /* tissue index of refraction */
radial_size = 3.0;        /* maximum radial size */

// Define the number of grid and photon
NR = 1000;                     /* number of radial positions */
dr= radial_size / NR;         // Radial bin size
config const Nphotons = 1000000;       /* number of photons in simulation */

proc main() { 
       
    var t: stopwatch;
    // Grid size
    var	Csph: [0..NR] real;  /* spherical   photon concentration CC[ir=0..100] */
    var	Ccyl: [0..NR] real;  /* cylindrical photon concentration CC[ir=0..100] */
    var	Cpla: [0..NR] real;  /* planar      photon concentration CC[ir=0..100] */

    t.start();
        forall i in 1..Nphotons with (+ reduce Csph, + reduce Ccyl, + reduce Cpla) {
        var RandGen = new randomStream(real,i); /* random number generator */
        var p = new photon(RandGen);
        do {
            p.hop(RandGen);
            p.drop();
            /* DROP absorbed weight into bin */
            Csph[p.spherical()] += p.absorb;
            Ccyl[p.cylindrical()] += p.absorb;
            Cpla[p.planar()] += p.absorb;
            p.spin(RandGen);
            p.update(RandGen);
            } while (p.photon_status );// If photon dead, then launch new photon
        } /* end RUN */
    t.stop();
writeln("Number of hardware threads available: ", here.maxTaskPar);
writeln("Number of locales: ", numLocales);

    // Compute the radial position
    var ir: [0..NR] int = 0..NR;
    var r = (ir + 0.5) * dr;

    // Compute shell volume
    var shellvolume_sph = 4.0 * PI * r * r * dr;
    var shellvolume_cyl = 2.0 * PI * r * dr;
    var shellvolume_pla = dr;

    // Compute fluence rates as vectors
    var Fsph = Csph / (Nphotons * mua * shellvolume_sph):real;
    var Fcyl = Ccyl / (Nphotons * mua * shellvolume_cyl):real;
    var Fpla = Cpla / (Nphotons * mua * shellvolume_pla):real;

    var flu: [0..NR, 0..3] real;
    flu[0..NR, 0] = r;
    flu[0..NR, 1] = Fsph;
    flu[0..NR, 2] = Fcyl;
    flu[0..NR, 3] = Fpla;

    /* print header */
    writef("number of photons = %i\n", Nphotons);
    writef("bin size = %5.5dr [cm] \n", dr);
    writef("last row is overflow. Ignore.\n");

    /* print column titles */
    writef("r [cm] \t\t Fsph [1/cm2] \t Fcyl [1/cm2] \t Fpla [1/cm2]\n");
    for i in 0..NR {
        writef("%5.5dr \t %4.3er \t %4.3er \t %4.3er \n", flu[i, 0], flu[i, 1], flu[i, 2], flu[i, 3]);
    }
    writeln("Number of photons : ", Nphotons);
    writeln("MPhotons/s : ", Nphotons/t.elapsed()/1_000_000);
    writeln("Elapsed time(s) : ", t.elapsed());
}