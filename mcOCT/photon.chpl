 // Include all functions related to a photon in MC simulation in Chapel

module photon {
    use Math;
    use Random;
    const PI = Math.pi;
    const ONE_MINUS_COSZERO = 1.0E-12;

    record mcPhoton {
    // coordinates of the photon
    var x: real;
    var y: real;
    var z: real;

    // cos direction of the photon
    var ux: real;
    var uy: real;
    var uz: real;
    var weight: real ;

    // Photon parameters
    var opl: real = 0.0; // intial value is 0
    var s: real = 0.0; // step size
    var maxDepth: real = 0.0; // the maximum depth of a photon can reach

    // status
    var photonAlive: bool = true;
    var escapeStatus: bool = false;

    // Refracts the photon direction at the boundary between two media
    proc rfPhoton(n1: real, n2: real): (real, real, real) {
        const sinTheta1 = sqrt(ux**2 + uy**2);
        const cosTheta1 = uz;
        const sinTheta2 = (n1 / n2) * sinTheta1;

        if sinTheta2 > 1.0 {
        // Total internal reflection
        return (-ux, -uy, -uz);
        }

        const cosTheta2 = sqrt(1.0 - sinTheta2**2);
        const scalingFactor = if sinTheta1 != 0 then sinTheta2 / sinTheta1 else 0.0;
        const vxNew = ux * scalingFactor;
        const vyNew = uy * scalingFactor;
        const vzNew = cosTheta2;

        return (vxNew, vyNew, vzNew);
    }

    // Computes Fresnel reflectance
    proc rFresnel(n1: real, n2: real, iAng: real): real {
        //iAng: Cosine of the incident angle (0 < a1 < 90 degrees)
        assert(iAng >= 0.0 && iAng <= 1.0, "Cosine of the incident angle must be between 0 and 1");
        if n1 == n2 {                              // Same medium
            return 0.0;
        }
        else if abs(iAng - 1) < ONE_MINUS_COSZERO { // Normal incidence
            const r = ((n2 - n1) / (n2 + n1))**2;
            return r;
        }
        else if iAng < 1.0E-6 {                     // Very small angle
            return 1.0;
        }
        else {                                      // General case
        
            const sa1 = sqrt(1.0 - iAng**2);
            const sa2 = (n1 * sa1) / n2;

            if sa2 >= 1.0 {
                return 1.0;
            }
            else {
                const oAng = sqrt(1.0 - sa2**2);
                const cap = iAng * oAng - sa1 * sa2;
                const cam = iAng * oAng + sa1 * sa2;
                const sap = sa1 * oAng + iAng * sa2;
                const sam = sa1 * oAng - iAng * sa2;
                return 0.5 * (sam**2/sap**2) * (1 + cap**2/cam**2);
            }
        }
    }

    // Performs the MOVE step for a photon
    proc ref mPhoton(mua: real, mus: real, n1: real, n2: real, ref rng) {
        var rnd = rng.next();
        while rnd <= 0.0 {
            rnd = rng.next();
        }
        s = -log(rnd) / (mua + mus);

        // Move the photon and update the position
        x = x + s * ux;
        y = y + s * uy;
        z = z + s * uz;
        // update the optical path length
        opl += s; 
   
        // Check if the photon has reached the boundary
        // If escap then end the photon
        if z <= 0.0 {            
            rnd = rng.next();
            var rF = rFresnel(n2, n1, -uz); 
            //writeln ("rF: ", rF, ' rnd: ', rnd);
            if rnd > rF {                       // Photon is refracted amd escaped
                x -= s * ux;                    // back to the original position
                y -= s * uy;
                z -= s * uz;
                const sToSurface = abs(z / uz);
                x += sToSurface * ux;           // Move to the surface
                y += sToSurface * uy;
                // z += sToSurface * uz;
                z = 0;                         // Photon is enforeced to 0
                (ux, uy, uz) = rfPhoton(n2, n1);// Refract the photon
                photonAlive = false;
                escapeStatus = true;            // Photon has escaped
                opl += sToSurface -s;          // update the optical path length due to escape
                } 
            else {                             // Photon reflrcted
                z = -z;
                uz = -uz;
                }
            }
        // record the maximum depth of the photon    
        if z > maxDepth {
            maxDepth = z;
        }    
    }

    // Scatters photon into a new direction
    proc ref spinPhoton(g: real, ref rng) {
        var costheta: real;
        if g == 0.0 {
            costheta = 2.0 * rng.next() - 1.0; // isotropic scattering
        } else {
            const temp = (1.0 - g * g) / (1.0 - g + 2 * g * rng.next()); // anisotropic (Henyey-Greenstein) scattering
            costheta = (1.0 + g * g - temp * temp) / (2.0 * g);
        }

        const sintheta = sqrt(1.0 - costheta**2);

        // Generate a random angle psi
        const phi = 2.0 * PI * rng.next();
        const cosphi = cos(phi);
        const sinphi = sin(phi);

        // Check if the old direction is close to the z-axis
        if 1.0 - abs(uz) <= ONE_MINUS_COSZERO {
            ux = sintheta * cosphi;
            uy = sintheta * sinphi;
            uz = costheta * (if uz >= 0.0 then 1.0 else -1.0);
        } 
        else {
            var temp = sqrt(1.0 - uz**2);
            ux = sintheta * (ux * uz * cosphi - uy * sinphi) / temp + ux * costheta;
            uy = sintheta * (uy * uz * cosphi + ux * sinphi) / temp + uy * costheta;
            uz = -sintheta * cosphi * temp + uz * costheta;


           // writeln("norm: ", norm); // for test on;y
        }
        var norm = sqrt(ux * ux + uy * uy + uz * uz);
        ux = ux / norm;
        uy = uy / norm;
        uz = uz / norm;
      }

    // Drops the photon weight
    proc ref dropPhoton(albedo: real) {
        weight = weight*albedo;
      }
    }
}
