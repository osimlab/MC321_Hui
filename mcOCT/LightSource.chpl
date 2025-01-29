
module LightSource {
  use Math;
  use Random;
  const PI = Math.pi;

  // Returns initial photon position for a pencil beam
  proc pencilBeam(): (real, real, real, real, real, real) {
    return (0.0, 0.0, 0.0, 0.0, 0.0, 1.0);
  }

 
  proc gaussianBeam(w0: real, zf: real, wl: real, ref rng): (real, real, real, real, real, real) {
    /*
    Generates the initial position and direction cosines of a single photon
    from a Gaussian beam for Monte Carlo simulations.

    Parameters:
        w0 (real): Beam waist (radius at which the field amplitude decreases to 1/e,mm).
        zf (real): Distance between the launch plane and the focus (positive value, mm).
        wl (real): Wavelength of the light (um).
        rng (): random number generator instance.

    Returns:
        x (real): x-coordinate of the photon position.
        y (real): y-coordinate of the photon position.
        z (real): z-coordinate of the photon position.
        ux (real): x-component of the direction cosine.
        uy (real): y-component of the direction cosine.
        uz (real): z-component of the direction cosine.
    */

    const z = 0.0;
    // Rayleigh range
    const zr = PI * w0 ** 2 / (wl * 0.001);
    //position ratio
    const t = -zf / zr;

    // Step 1: Sample a radial position 'r0' according to the Gaussian beam intensity profile
    const U_r = rng.next();
    const r0 = w0 * sqrt(-0.5 * log(U_r));

    // Step 2: Sample an azimuthal angle 'theta' uniformly in [0, 2*pi]
    const theta = 2.0 * PI * rng.next();
    
    // Step 3: Calculate the initial position
    const sinTheta = sin(theta);
    const cosTheta = cos(theta);
    const x = r0 * (cosTheta - t * sinTheta);
    const y = r0 * (sinTheta + t * cosTheta);

    // Step 4: Calculate the direction cosines
    const l = sqrt(r0**2 + zr**2);
    const ux = -r0 * sinTheta / l;
    const uy = r0 * cosTheta / l;
    const uz = zr / l;

    return (x, y, z, ux, uy, uz);
  }
}