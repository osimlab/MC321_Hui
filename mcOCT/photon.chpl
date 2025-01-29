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
    var weight: real;

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
    proc ref mPhoton(mua: real, mus: real, n1: real, n2: real, ref rng): (real, real, real, real, real, real, real, bool, bool) {
        var rnd = rng.next();
        while rnd <= 0.0 {
            rnd = rng.next();
        }
        const s = -log(rnd) / (mua + mus);

        var newX = x + s * ux;
        var newY = y + s * uy;
        var newZ = z + s * uz;
        var photonAlive = true;
        var escapeStatus = false;

        if newZ <= 0.0 {            // Photon reaches the boundary 
            rnd = rng.next();
            //var rF = rFresnel(n2, n1, -uz); # for unit test
            //writeln ("rF: ", rF, ' rnd: ', rnd);
            if rnd > rF {
                newX -= s * ux;
                newY -= s * uy;
                newZ -= s * uz;
                const sToSurface = abs(newZ / uz);
                newX += sToSurface * ux;
                newY += sToSurface * uy;
                newZ += sToSurface * uz;
                (ux, uy, uz) = rfPhoton(n2, n1); // Refract the photon from the medium to the air
                photonAlive = false;
                escapeStatus = true;
                } 
            else {
                newZ = -newZ;
                uz = -uz;
                }
            }
        return (newX, newY, newZ, ux, uy, uz, s, photonAlive, escapeStatus);
    }


    // Scatters photon into a new direction
    proc ref spinPhoton(g: real, ref rng): (real, real, real) {
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
            const uxx = sintheta * cosphi;
            const uyy = sintheta * sinphi;
            const uzz = costheta * (if uz >= 0.0 then 1.0 else -1.0);
            return (uxx, uyy, uzz);
        } 
        else {
            const temp = sqrt(1.0 - uz**2);
            const uxx = sintheta * (ux * uz * cosphi - uy * sinphi) / temp + ux * costheta;
            const uyy = sintheta * (uy * uz * cosphi + ux * sinphi) / temp + uy * costheta;
            const uzz = -sintheta * cosphi * temp + uz * costheta;

            const norm = sqrt(uxx * uxx + uyy * uyy + uzz * uzz);
           // writeln("norm: ", norm); // for test on;y
            return (uxx / norm, uyy / norm, uzz / norm);
        }
      }
    // Drops the photon weight
    proc dropPhoton(albedo: real): real {
        const absorb = weight * (1.0 - albedo);
        return weight - absorb;
      }
    }
}
