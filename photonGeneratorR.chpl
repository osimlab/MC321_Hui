module photonGeneratorR {
    use Math;
    use Random;

    // Define constants and parameters
    param PI = 3.1415926;
    param ONE_MINUS_COSZERO = 1.0E-12;
    param THRESHOLD = 0.01;    // Used in roulette
    param CHANCE = 0.1;        // Used in roulette

    // Define optical properties (public variables)
    public config var mua: real;       // Absorption coefficient [cm^-1]
    public var mus: real;      // Scattering coefficient [cm^-1]
    public var albedo: real;    // Albedo of tissue   
    public var g: real;        // Anisotropy [-]
    public var nt: real;       // Tissue index of refraction
    public var radial_size: real;  // Maximum radial size [cm]

    // Grid parameters (public variables)
    public var NR: int;         // Number of radial positions
    public var dr: real;              // Radial bin size

    // Utility function
    inline proc SIGN(x) do return (if x>=0 then 1 else -1);

    // Photon record
    public record photon {
        // Propagation parameters
        var x, y, z: real = 0 ;         /* photon position */
        var ux, uy, uz: real = 0;      /* photon trajectory as cosines */
        var W: real = 1;               /* photon weight */
        var absorb:real;               /* weighted deposited in a step due to absorption */
        var photon_status: bool = true;  /* true: ALIVE or false: DEAD */ 
        // var x2Plusy2: real;
        var rr: real;
        }

    // Initializes the photon and simulate an isotropic point source to all directions
    proc photon.init(ref rng) {
        const costheta = 2.0 * rng.next() - 1.0;     // Randomly set the photon's trajectory relative to Z [-1.1] or[-pi,pi] to yield an isotropic source
        const sintheta = sqrt(1.0 - costheta **2);      // Always positive
        const psi = 2.0 * PI * rng.next();           //Azimuthal Angle: Random angle in the range [0, 2*PI)
        ux = sintheta * cos(psi);
        uy = sintheta * sin(psi);  
        uz = costheta;
        }

    // Hop: Update current position based on random scattering.
    inline proc ref photon.hop(ref rng) {
        var rnd: real = rng.next();             // Generate a random number rnd in the range (0, 1] to generate a step size
        const stepSize = -log(rnd) / (mua + mus);  // Step size is the distance to the next interaction
        
        // Update the photon's position
        x += stepSize * ux;
        y += stepSize * uy;
        z += stepSize * uz;
        // Compute the squared radial distance from the origin
        rr = x**2+ y**2;
        }
    
    // Drop: Decrease weight by the absorbed amount
    inline proc ref photon.drop() {
        absorb = W * (1.0 - albedo);   // `albedo` is the scattering albedo (mus / (mua + mus))
        W -= absorb;                   // Decrease weight by the absorbed amount
        }

    inline proc ref photon.spherical() {
        const r = sqrt(rr + z*z);    /* current spherical radial position */
        const ir = min((r/dr): int(64), NR);
        return ir;
        }

    inline proc ref photon.cylindrical() {
        const r = sqrt(rr);          /* current cylindrical radial position */
        const ir = min((r/dr): int(64), NR);
        return ir;
        }

    inline proc ref photon.planar() {
        const r = abs(z);                  /* current planar radial position */
        const ir = min((r/dr): int(64), NR);
        return ir;
        }

    // Spin: Update direction after scattering
    inline proc ref photon.spin(ref rng) {
        var uxx, uyy, uzz: real;
        // Sample for cos(theta)
        var rnd = rng.next();
        var costheta: real;
        if g == 0.0 {
        costheta = 2.0 * rnd - 1.0;
        } else {
        const temp = (1.0 - g * g) / (1.0 - g + 2.0 * g * rnd);
        costheta = (1.0 + g * g - temp * temp) / (2.0 * g);
        }
        const sintheta = sqrt(1.0 - costheta * costheta);
        // Sample psi
        const psi = 2.0 * PI * rng.next();
        const cospsi = cos(psi);
        const sinpsi = sin(psi);

    // if psi < PI then
    // sinpsi = sqrt(1.0 - cospsi * cospsi);
    // else
    // sinpsi = -sqrt(1.0 - cospsi * cospsi);

        // New trajectory
        if 1.0 - abs(uz) <= ONE_MINUS_COSZERO {
        uxx = sintheta * cospsi;
        uyy = sintheta * sinpsi;
        uzz = costheta * SIGN(uz);
        } else {
        const temp = sqrt(1.0 - uz * uz);
        uxx = sintheta * (ux * uz * cospsi - uy * sinpsi) / temp + ux * costheta;
        uyy = sintheta * (uy * uz * cospsi + ux * sinpsi) / temp + uy * costheta;
        uzz = -sintheta * cospsi * temp + uz * costheta;
        }

        // Update trajectory
        ux = uxx;
        uy = uyy;
        uz = uzz;
    }
    // Update photon status based on weight
    proc ref photon.update(ref rng) {
        if W < THRESHOLD {
            if rng.next() <= CHANCE then
            W /= CHANCE;
        else
            photon_status = false;
        }
    }
}