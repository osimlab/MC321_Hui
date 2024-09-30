use Math, Time;
use Random.NPBRandom;

// Initialize NPBRandomStream with a seed

param PI         = 3.1415926;
param LIGHTSPEED = 2.997925E10; /* in vacuo speed of light [cm/s] */
param ALIVE      = 1;		    /* if photon not yet terminated */
param DEAD       = 0;		    /* if photon is to be terminated */
param THRESHOLD  = 0.01;		/* used in roulette */
param CHANCE     = 0.1;		    /* used in roulette */
param COS90D     = 1.0E-6;
inline proc SIGN(x) do return (if x>=0 then 1 else -1);
param ONE_MINUS_COSZERO = 1.0E-12; /* If cos(theta) <= COS90D, theta >= PI/2 - 1e-6 rad. */

param mua = 1.0;               /* absorption coefficient [cm^-1] */
param mus = 0.0;               /* scattering coefficient [cm^-1] */
param g = 0.90;                /* anisotropy [-] */
param nt = 1.33;               /* tissue index of refraction */
param radial_size = 3.0;       /* maximum radial size */

/* IF NR IS ALTERED, THEN USER MUST ALSO ALTER THE ARRAY DECLARATION TO A SIZE = NR + 1. */
param NR: int = 100;                     /* number of radial positions */
param dr = radial_size/NR;               /* radial bin size */
param albedo = mus/(mus+mua);            /* albedo of tissue */
config const Nphotons = 1_000_000;      /* number of photons in simulation */

// Photon record
record photon {
  /* Propagation parameters */
  var x, y, z:real;         /* photon position */
  var ux, uy, uz:real;      /* photon trajectory as cosines */
  var W:real;               /* photon weight */
  var absorb:real;          /* weighted deposited in a step due to absorption */
  var photon_status: bool;  /* true: ALIVE=1 or false: DEAD */ 
  var x2Plusy2: real;
}

// Initializes the photon 
// Simulate an isotropic point source. Sets the photon's weight=1 and the position at the origin (0,0,0), and assigns a random direction.
// Arguments: - `rng`: A reference to the random number generator.
proc photon.init(rng: borrowed NPBRandomStream) {
    init this;                  // Initialize the photon's weight and status when the photon is created
    W = 1.0;                    // Set photon weight to one
    photon_status = true;       // Launch an ALIVE photon

    x = 0.0;
    y = 0.0;
    z = 0.0;
   
    const costheta = 2.0 * rng.getNext() - 1.0;    // Randomly set the photon's trajectory relative to Z [-1.1] or[-pi,pi] to yield an isotropic source
    const sintheta = sqrt(1.0 - costheta **2);  // Always positive
    const psi = 2.0 * PI * rng.getNext();          //Azimuthal Angle: Random angle in the range [0, 2*PI)
    ux = sintheta * cos(psi);
    uy = sintheta * sin(psi);  
    uz = costheta;
}

// Performs a hop step for the photon, updating its position based on random scattering.
inline proc ref photon.hop(rng: borrowed NPBRandomStream) {
    var rnd: real; // Generate a random number rnd in the range (0, 1] to generate a step size
    do {
        rnd = rng.getNext();
    } while rnd <= 0.0;

    const stepSize = -log(rnd) / (mua + mus);  // Step size is the distance to the next interaction
    // Update the photon's position
    x += stepSize * ux;
    y += stepSize * uy;
    z += stepSize * uz;

    // Compute the squared radial distance from the origin
    x2Plusy2 = x**2+ y**2;
}

inline proc ref photon.drop() {
    absorb = W * (1.0 - albedo);   // `albedo` is the scattering albedo (mus / (mua + mus))
    W -= absorb;                   // Decrease weight by the absorbed amount
}

inline proc ref photon.spherical() {
  const r = sqrt(x2Plusy2 + z*z);    /* current spherical radial position */
  const ir = min((r/dr): int(16), NR);
  return ir;
}

inline proc ref photon.cylindrical() {
  const r = sqrt(x2Plusy2);          /* current cylindrical radial position */
  const ir = min((r/dr): int(16), NR);
  return ir;
}

inline proc ref photon.planar() {
  const r = abs(z);                  /* current planar radial position */
  const ir = min((r/dr): int(16), NR);
  return ir;
}

inline proc ref photon.spin(rng: borrowed NPBRandomStream) {
 // temporary values used during SPIN 
  var uxx, uyy, uzz:real;	

  //Sample for cos(theta), the cosine of the scattering angle
    var rnd = rng.getNext();
    const costheta;
    if g == 0.0 {
        // Isotropic scattering
        costheta = 2.0 * rnd - 1.0;
    } else {
        // Anisotropic scattering using the Henyey-Greenstein phase function
        const temp = (1.0 - g * g) / (1.0 - g + 2.0 * g * rnd);
        costheta = (1.0 + g * g - temp * temp) / (2.0 * g);
    };
  
  //Calculate sin(theta), ensuring it's non-negative
  const sintheta = sqrt(1.0 - costheta*costheta); 

  /* Sample psi. */
  const psi = 2.0*PI*rng.getNext(); // Random angle in the range [0, 2*PI)
  const cospsi = cos(psi);
  const sinpsi;
  if (psi < PI) then
    sinpsi = sqrt(1.0 - cospsi*cospsi);     /* sqrt() is faster than sin(). */
  else
    sinpsi = -sqrt(1.0 - cospsi*cospsi);

  /* New trajectory. */
  if (1 - abs(uz) <= ONE_MINUS_COSZERO) {      /* close to perpendicular. */
    uxx = sintheta * cospsi;
    uyy = sintheta * sinpsi;
    uzz = costheta * SIGN(uz);   /* SIGN() is faster than division. */
  }
  else {					/* usually use this option */
    const temp = sqrt(1.0 - uz * uz);
    uxx = sintheta * (ux * uz * cospsi - uy * sinpsi) / temp + ux * costheta;
    uyy = sintheta * (uy * uz * cospsi + ux * sinpsi) / temp + uy * costheta;
    uzz = -sintheta * cospsi * temp + uz * costheta;
  }

  /* Update trajectory */
  ux = uxx;
  uy = uyy;
  uz = uzz;
}

proc ref photon.update(rng: borrowed NPBRandomStream) {
  if (W < THRESHOLD) {
    if (rng.getNext() <= CHANCE) then
      W /= CHANCE;
    else photon_status = false;
  }
}


proc main() {

    var t: stopwatch;
    // Grid size
    var	Csph: [0..100] real;  /* spherical   photon concentration CC[ir=0..100] */
    var	Ccyl: [0..100] real;  /* cylindrical photon concentration CC[ir=0..100] */
    var	Cpla: [0..100] real;  /* planar      photon concentration CC[ir=0..100] */

   t.start();
   forall i in 1..Nphotons {

    var RandGen = new NPBRandomStream(real(64),2*i+1, true); /* random number generator */
    var p = new photon(RandGen );
    do {
        p.hop(RandGen);
        p.drop();

        /* DROP absorbed weight into bin */
        //gpuAtomicAdd(Csph[p.spherical()], p.absorb);
        Csph[p.spherical()] += p.absorb;

        /* DROP absorbed weight into bin */
        //gpuAtomicAdd(Ccyl[p.cylindrical()], p.absorb);
        Ccyl[p.cylindrical()] += p.absorb;

        /* DROP absorbed weight into bin */
        Cpla[p.planar()] += p.absorb;
        
        p.spin(RandGen );
        p.update(RandGen );
    } /* end STEP_CHECK_HOP_SPIN */
    while (p.photon_status );
    /*while false;*/
    /* If photon dead, then launch new photon. */
    } /* end RUN */

    t.stop();

    /* print header */
    writef("number of photons = %i\n", Nphotons);
    writef("bin size = %5.5dr [cm] \n", dr);
    writef("last row is overflow. Ignore.\n");

    /* print column titles */
    writef("r [cm] \t Fsph [1/cm2] \t Fcyl [1/cm2] \t Fpla [1/cm2]\n");

    /* print data:  radial position, fluence rates for 3D, 2D, 1D geometries */
    for ir in 0..NR {
      /* r = sqrt(1.0/3 - (ir+1) + (ir+1)*(ir+1))*dr; */
      const r = (ir + 0.5)*dr;
      var shellvolume = 4.0*PI*r*r*dr; /* per spherical shell */
      /* fluence in spherical shell */
      const Fsph = Csph[ir]/Nphotons/shellvolume/mua;
      shellvolume = 2.0*PI*r*dr;   /* per cm length of cylinder */
      /* fluence in cylindrical shell */
      const Fcyl = Ccyl[ir]/Nphotons/shellvolume/mua;
      shellvolume = dr;            /* per cm2 area of plane */
      /* fluence in planar shell */
      const Fpla =Cpla[ir]/Nphotons/shellvolume/mua;
      writef("%5.5dr \t %4.3er \t %4.3er \t %4.3er \n", r, Fsph, Fcyl, Fpla);
    }
  
  writeln("Number of photons : ", Nphotons);
  writeln("MPhotons/s : ", Nphotons/t.elapsed()/1_000_000);
  writeln("Elapsed time(s) : ", t.elapsed());
} /* end of main */