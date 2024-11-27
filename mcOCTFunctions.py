import math
import random
import numpy as np

PI = math.pi
ONE_MINUS_COSZERO = 1.0E-12  # 1 minus cosine of angle close to 0 degrees
# ---------------------------------------------------------------
'''
REFRACTION: calculate the photon refraction at the boundary between two media
'''
def refract_photon(vx, vy, vz, n1, n2):
    """
    Calculate the new direction cosines of a photon after refraction.

    Parameters:
    - vx, vy, vz: Direction cosines of the photon.
    - n1, n2: Refractive indices of the two media.

    Returns:
    - (vx_new, vy_new, vz_new): New direction cosines after refraction.
    """
    # Calculate sin(theta1) and cos(theta1): the incident angle
    sin_theta1 = np.sqrt(vx**2 + vy**2)
    cos_theta1 = vz

    # Snell's law to find sin(theta2)
    sin_theta2 = (n1 / n2) * sin_theta1

    if sin_theta2 > 1:
        # Total internal reflection
        return -vx, -vy, -vz  # Reflect the photon

    # Calculate cos(theta2)
    cos_theta2 = np.sqrt(1 - sin_theta2**2)

    # Scale vx and vy for the new direction
    scaling_factor = sin_theta2 / sin_theta1 if sin_theta1 != 0 else 0
    vx_new = vx * scaling_factor
    vy_new = vy * scaling_factor
    vz_new = cos_theta2

    return vx_new, vy_new, vz_new
# ---------------------------------------------------------------
''' 
FRESNEL REFLECTANCE: Computes reflectance as photon passes from medium 1 to medium 2 with refractive indices n1,n2. Incident angle a1 is specified by cosine value iAng = cos(a1).Program returns the reflatance to determine the light reflection at the boundary between two media.
'''
def RFresnel(n1, n2, iAng):
    """
    Parameters:
    - n1: Incident refractive index.
    - n2: Transmitting refractive index.
    - iAng: Cosine of the incident angle (0 < a1 < 90 degrees).This value has to be positive.

    Returns:
    - r: Fresnel reflectance.
    - oAng: Cosine of the transmission angle (a2 > 0).
    """
    if n1 == n2:                      # Matched boundary
        oAng = iAng
        r = 0.0

    elif abs(iAng-1) < ONE_MINUS_COSZERO:  # Normal incidence
        oAng = iAng = 1.0
        r = (n2 - n1) / (n2 + n1)
        r *= r

    elif iAng < 1.0e-6:                # horizontal incidence
        oAng = 0.0
        r = 1.0

    else:  # General case
        sa1 = math.sqrt(1 - iAng**2)  # Sine of the incident angle
        sa2 = n1 * sa1 / n2           # Sine of the transmission angle

        if sa2 >= 1.0:                # Total internal reflection
            oAng = 0.0
            r = 1.0

        else:
            oAng = math.sqrt(1 - sa2**2)   # Cosine of the transmission angle
            cap = iAng * oAng - sa1 * sa2  # Cosine of the sum of angles
            cam = iAng * oAng + sa1 * sa2  # Cosine of the difference of angles
            sap = sa1 * oAng + iAng * sa2  # Sine of the sum of angles
            sam = sa1 * oAng - iAng * sa2  # Sine of the difference of angles

            # Compute Fresnel reflectance
            r = 0.5 * (sam**2) * (cam**2 + cap**2) / (sap**2 * cam**2)

    return r

# ---------------------------------------------------------------
def MOVE(x, y, z, ux, uy, uz, mua, mus,rng, photon_alive, escape_status, n1, n2):
    """
    Perform the HOP step: move the photon to a new position.

    Parameters:
        x, y, z (float): Current photon position coordinates.
        ux, uy, uz (float): Current photon trajectory cosines.
        mua (float): Absorption coefficient [cm^-1].
        mus (float): Scattering coefficient [cm^-1].
        photon_status (int): Photon status (0 = alive, 1 = absorbed)

    Returns:
        x, y, z (float): Updated photon position coordinates.
        s (float): Step size taken [cm].
    """
    rnd = rng.random()
    while rnd <= 0.0:                 # Prevent zero or negative random numbers
        rnd = rng.random()
    s = -math.log(rnd) / (mua + mus)  # Step size [cm]

    # Update photon position
    x += s * ux
    y += s * uy
    z += s * uz
    #print("Photon position: ", x, y, z)
    
    # Check if photon escapes at the surface (z <= 0). If the photon escapes, ending the photon at the surface and set escape status to 1; otherwise, the photon will be reflected back into the medium.
    if z <= 0:
        rnd = rng.random()
        if rnd > RFresnel(n1, n2, -uz): # -uz is the cosine of the incident angle relative to the surface normal, has to be positive.
        # Photon escapes at the surface
            x -= s * ux      # Return to original position
            y -= s * uy
            z -= s * uz
            #print("to original position: ", x, y, z)
            s = abs(z / uz)  # Step size to surface
            x += s * ux      # Partial step to surface
            y += s * uy
            z += s * uz
            #print("Partial step to surface: ", x, y, z)
            ux, uy, uz = refract_photon(ux, uy, -uz, n1, n2)  # Refracted photon directional cosines
            photon_alive = False
            escape_status = True
        else: 
            #print ("Photon is reflected back into the medium")
            z = -z 
            uz = -uz        # Reverse photon trajectory as total internal reflection occurs

    return x, y, z, ux, uy, uz, s, photon_alive, escape_status

#--------------------------------------------------------------
def DROP(W, albedo):
    """
    Perform the DROP step: update photon weight and accumulate absorbed weight in spatial bins.

    Parameters:
        W (float): Current photon weight.
        albedo (float): Albedo (scattering probability).
    Returns:
        W (float): Updated photon weight after absorption.
    """
    # Calculate absorbed weight and update photon weight
    absorb = W * (1.0 - albedo)  # Absorbed weight during this step
    W -= absorb                  # Decrease photon weight by absorbed amount

    # Accumulate absorbed weight in spatial bins, which are surfaces defined in spherical surface, cylindrical, and planar coordinates

    return W
#--------------------------------------------------------------
def SPIN(ux, uy, uz, g, rng):
    """
    Perform the SPIN step: scatter photon into a new direction.

    Parameters:
        ux, uy, uz (float): Current photon trajectory cosines.
        g (float): Anisotropy factor.

    Returns:
        ux, uy, uz (float): Updated photon trajectory cosines.
    """
    # Sample scattering angle theta using Henyey-Greenstein phase function
    if g == 0.0:
        costheta = 2.0 * rng.random() - 1.0
    else:
        temp = (1.0 - g * g) / (1.0 - g + 2 * g * rng.random())
        costheta = (1.0 + g * g - temp * temp) / (2.0 * g)
    
    sintheta = math.sqrt(1.0 - costheta * costheta)  # Sine of theta
    #print("sintheta: ", sintheta)
    #print("costheta: ", costheta)

    # Sample azimuthal angle psi uniformly from [0, 2PI]
    psi = 2.0 * PI * rng.random() 
    cospsi = math.cos(psi)
    sinpsi = math.sin(psi)

    # Update photon trajectory based on new angles
    if 1 - abs(uz) <= ONE_MINUS_COSZERO:
        # Near perpendicular incidence
        uxx = sintheta * cospsi
        uyy = sintheta * sinpsi
        uzz = costheta * (1 if uz >= 0 else -1)
    else:
        # General case
        temp = math.sqrt(1.0 - uz**2)
        #print("temp: ", temp)
        uxx = sintheta * (ux * uz * cospsi - uy * sinpsi) / temp + ux * costheta
        uyy = sintheta * (uy * uz * cospsi + ux * sinpsi) / temp + uy * costheta
        uzz = -sintheta * cospsi * temp + uz * costheta


    # Normalize the direction cosines to prevent accumulation of errors
    norm = math.sqrt(uxx * uxx + uyy * uyy + uzz * uzz)
    #print("norm: ", norm)
    ux = uxx / norm
    uy = uyy / norm
    uz = uzz / norm

    return ux, uy, uz

#--------------------------------------------------------------
# Pensil Beam　
def PENSIL_BEAM():
    """
    Returns:
        x, y, z (float): Photon position coordinates.
        ux, uy, uz (float): Photon trajectory cosines.
    """
    x = y = z = 0.0
    ux = uy = 0.0
    uz = 1.0
    return x, y, z, ux, uy, uz
#--------------------------------------------------------------
# Focused Gasussian Beam Light Source 
def Gaussian_FBEAM(w0, zf, wl, rng):
    """
    Generates the initial position and direction cosines of a single photon
    from a Gaussian beam for Monte Carlo simulations.

    Parameters:
        w0 (float): Beam waist (radius at which the field amplitude decreases to 1/e,mm).
        zf (float): Distance between the launch plane and the focus (positive value, mm).
        wl (float): Wavelength of the light (um).
        rng (np.random.Generator): NumPy random number generator instance.

    Returns:
        x (float): x-coordinate of the photon position.
        y (float): y-coordinate of the photon position.
        z (float): z-coordinate of the photon position.
        ux (float): x-component of the direction cosine.
        uy (float): y-component of the direction cosine.
        uz (float): z-component of the direction cosine.
    """
    z = 0 # Initial position of the photon
    # Calculate the Rayleigh range
    zr = np.pi * w0**2 / (wl*0.001)

    # Parameter 't' used in the position calculation
    t = -zf / zr

    # Step 1: Sample a radial position 'r0' according to the Gaussian beam intensity profile
    U_r = rng.random()
    r0 = w0 * np.sqrt(-0.5 * np.log(U_r))

    # Step 2: Sample an azimuthal angle 'theta' uniformly between 0 and 2*pi
    theta = 2.0 * np.pi*rng.random()

    # Step 3: Calculate the initial position
    cos_theta = np.cos(theta)
    sin_theta = np.sin(theta)

    x = r0 * (cos_theta - t * sin_theta)
    y = r0 * (sin_theta + t * cos_theta)

    # Step 4: Calculate the direction cosines
    l = np.sqrt(r0**2 + zr**2)
    ux = -r0 * sin_theta / l
    uy = r0 * cos_theta / l
    uz = zr / l

   # print("Initial position: ", ux, uy, uz)

    return x, y, z, ux, uy, uz