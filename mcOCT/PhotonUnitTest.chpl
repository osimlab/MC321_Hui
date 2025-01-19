use Random;
use Math;
use photon;

// Unitest all functions in photon module
// 1. Test rfPhoton()
proc testrfPhoton() {
  writeln("...Testing refractPhoton() ...");

  // TEST: Normal incidence, n1 != n2
    //    ---------------------------------
    //    Same initial direction (straight down z-axis).
    //    If the direction is purely along z-axis, the direction
    //    should still remain along z-axis, regardless of n1 & n2,
    //    because sinTheta1 = 0 => sinTheta2 = 0.
  var ux = 0.0;            
  var uy = 0.0;
  var uz = 1.0;
  var n1 = 1.0, n2 = 1.5;

  var p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux , uy, uz, weight=1.0);
  var (rx, ry, rz) = p.rfPhoton(n1, n2);

  writeln("Test #1: Normal Incidence, Different Indices (n1=1, n2=1.5)");
  writeln("  Input direction = (", ux, ", ", uy, ", ", uz, ")");
  writeln("  Output direction = (", rx, ", ", ry, ", ", rz, ")");
  writeln("  Expected direction ~ (0, 0, 1) because normal incidence => no bending");
  writeln();

//TEST: Oblique incidence, partial refraction
//    -------------------------------------------
//    Let's choose an incident angle of 30° from the z-axis, in the x-z plane:
//      => cos(30°) = sqrt(3)/2, sin(30°) = 1/2
//      So we can set ux = 0.5, uy = 0, uz = sqrt(3)/2 (approx 0.86602540378).
//    We pick n1 = 1.0, n2 = 1.5 => we expect some bending, but not TIR.

var angleDeg = 30.0;
var angleRad = angleDeg * pi / 180.0;
ux = sin(angleRad);            // ~ 0.5
uy = 0.0;
uz = cos(angleRad);            // ~ 0.8660254
(n1,n2) = (1.0, 1.5);

p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux, uy, uz, weight=1.0);
(rx, ry, rz) = p.rfPhoton(n1, n2);

writeln("Test #2: Oblique Incidence, Partial Refraction (30°, n1=1, n2=1.5)");
writeln("  Input direction = (", ux, ", ", uy, ", ", uz, ")");
writeln("  Output direction = (", rx, ", ", ry, ", ", rz, ")");
writeln("  Expected rx = 0.333, ry = 0 , and rz = 0.943");
writeln("-----");

// 4) TEST: Oblique incidence leading to total internal reflection
//  ------------------------------------------------------------
//    TIR occurs if sinTheta2 > 1, i.e. sinTheta1 * (n1/n2) > 1.
//    Let’s pick an angle from z-axis that we know will cause TIR.
//    For example, if n1=1.5, n2=1.0, and the angle is large enough.
//    Suppose we set angle = 60°, sin(60°)=~0.8660, n1/n2=1.5/1.0=1.5
//    => sinTheta2 = 1.5 * 0.8660 = 1.299 (which is > 1 => TIR).

angleDeg = 60.0;
angleRad = angleDeg * pi / 180.0;
ux = sin(angleRad);    // ~ 0.8660
uy = 0.0;
uz = cos(angleRad);    // ~ 0.5
(n1,n2) = (1.5, 1.0);

p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux , uy, uz, weight=1.0);
(rx, ry, rz) = p.rfPhoton(n1, n2);

writeln("Test #3: TIR scenario (angle=60°, n1=1.5, n2=1.0)");
writeln("  Input direction = (", ux, ", ", uy, ", ", uz, ")");
writeln("  Output direction = (", rx, ", ", ry, ", ", rz, ")");
writeln("  Expected outcome => reflection: rx = ",-ux, " ry = ",-uy , " and rz = ",-uz);
writeln("-----");
} 

// 2. Test rFresnel()

proc testrFresnel() {
    writeln("...  Fresnel Reflectance tests ...");
// Test #1: identical medium (same n) 
// expected reflectance = 0.0 (normal incidence case)

    var p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux = 0, uy = 0, uz = 0, weight=1.0);
    var iAng = 0.0;
    var r = p.rFresnel(1.0, 1.0, iAng);

    writeln("Test #1: n1 = 1.0, n2 = 1.0, cos(theta)=1.0 (normal incidence)");
    writeln("  Result: ", r);
    writeln("  Expect: 0.0");
    assert(abs(r - 0.0) < 1.0e-14, "fresnelReflectance should be 0 when n1==n2 at normal incidence");
    writeln("---");

// Test #2:  normal incidence, n1 != n2
    iAng = 1.0;
    r = p.rFresnel(1.0, 1.5, iAng);

    writeln("Test #2: n1 = 1.0, n2 = 1.5, cos(theta)=1.0 (normal incidence)");
    writeln("  Result: ", r);
    writeln("  Expect: ~ 0.04");
    assert(abs(r - 0.04) < 1.0e-14, "fresnelReflectance should be ~0.04 at normal incidence with n1 != n2");
    writeln("---");

// Test #3:  oblique incidence, partial refraction
    iAng = cos(60.0 * pi / 180.0);
    r = p.rFresnel(1.0, 1.5,iAng);
    writeln("Test #3: n1 = 1.0, n2 = 1.5, cos(theta)=0.866 (30° incidence)");
    writeln("  Result: ", r);
    writeln("  Expect: ~ 0.089");
    writeln("---");

// Test total reflection
    iAng = cos(60.0 * pi / 180.0);
    var n1 = 1.0; 
    var n2 = 1.5;
    r = p.rFresnel(n2, n1, iAng);
    writeln("Test #4: light from 1.5 to 1.0, cos(theta)=0.5 (60° incidence)");
    writeln("  Result: ", r);
    writeln("  Expect: 1.0");
    assert(abs(r - 1.0) < 1.0e-14, "fresnelReflectance should be 1.0 at total internal reflection");
    writeln("---");
} 

// 3. Test mPhoton()
config const seed = 37;
proc testMPhoton() {
    writeln("... mPhoton tests ...");
    
    var rng = new randomStream(real, seed);

    // Test #1: a photon moving straight down the z-axis 
    var uz = 1.0, ux =0.0;
    var uy = sqrt(1 - ux**2 - uz**2);

    var p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux, uy, uz, weight=1.0);

    var mua = 1, mus = 10, n1 = 1.0, n2 = 1.5;
    var (nx, ny, nz, nux, nuy, nuz, s, Live, Escape) = p.mPhoton(mua, mus, n1, n2, rng);
    
    writeln("Test #1: Photon moving straight down the z-axis");
    writeln("Result: (", nx, ", ", ny, ", ", nz, ", ", nux, ", ", nuy, ", ", nuz, ", ", s, ", ", Live, ", ", Escape, ")");

    // Test #2:  a photon moving out of the medium
    uz = -0.5; // 60° from z-axis total internal reflection
    ux =0.0; 
    uy = sqrt(1 - ux**2 - uz**2);
    p = new mcPhoton(x = 0.0, y = 0.0, z = 0.01, ux , uy, uz, weight=1.0);
    (nx, ny, nz, nux, nuy, nuz, s, Live, Escape) = p.mPhoton(mua, mus, n1, n2, rng);

    writeln("Test #2: Photon total reflection");
    writeln ("Expected: nx = 0, ny = ",uy*s, ", nz = ", -(00.01+uz*s));
    writeln("Result: (", nx, ", ", ny, ", ", nz, ", ", nux, ", ", nuy, ", ", nuz, ", ", s, ", ", Live, ", ", Escape, ")");
    writeln("---");

    // Test #3:  a photon moving out the medium
    uz = -sqrt(3)/2; // 30° from z-axis total internal reflection
    ux =0.0; 
    uy = sqrt(1 - ux**2 - uz**2);
    var z = 0.01;
    p = new mcPhoton(x = 0.0, y = 0.0, z, ux , uy, uz, weight=1.0);
    (nx, ny, nz, nux, nuy, nuz, s, Live, Escape) = p.mPhoton(mua, mus, n1, n2, rng);

    writeln("Test #3: Photon moving out of the medium");
    writeln ("Expected: nx = 0, ny = ",uy*z/abs(uz), ", nz = ", 0);
    writeln("Result: (", nx, ", ", ny, ", ", nz, ", ", nux, ", ", nuy, ", ", nuz, ", ", s, ", ", Live, ", ", Escape, ")");
    writeln("-----");
}  

// 4. Test dropPhoton()
proc testDropPhoton() {
    writeln("... dropPhoton tests ...");
    var albedo: real;
    // Test case 1: Basic albedo
    albedo = 0.5;
    var p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux = 0.0, uy = 0.0, uz = 0.0, weight=1.0);
    writeln("Test #1: For albedo = 0.5");
    writeln ("Expected: 0.5");
    writeln("Result: ", p.dropPhoton(albedo));
    writeln("-----");
  
}
// 5. Test spinPhonton()
proc testSpinPhoton() {
   writeln("... spinPhoton tests ...");
  var seed = 37;
  var rng = new randomStream(real, seed);

  // Test #1: Check that for g = 0 (isotropic), the output is a unit vector
  // Repeated trials to ensure consistency
  var uz = 0.2; // 30° from z-axis total internal reflection
  var ux = 0; 
  var uy = sqrt(1 - ux**2 - uz**2);
  var p = new mcPhoton(x = 0.0, y = 0.0, z = 0.0, ux, uy, uz, weight=1.0);

  writeln("Test #1: Isotropic scattering (g = 0)");
  for i in 1..6 {
    const newDir = p.spinPhoton(0.0, rng);
    // Check magnitude is ~1
    const mag = sqrt(newDir(0)**2 + newDir(1)**2 + newDir(2)**2);
    writeln(" Result: ", i, " Newdirection: ", newDir);
   
  }
  writeln("---");

  writeln("Test #2: forward scattering (g = 0.95)");
  for i in 1..6 {
    const newDir = p.spinPhoton(0.95, rng);
    // Check magnitude is ~1
    const mag = sqrt(newDir(0)**2 + newDir(1)**2 + newDir(2)**2);
    writeln(" Result: ", i, " Newdirection: ", newDir);
  }
    writeln("Expected: all angles should be close to the original direction");
}

// Main program to run tests
proc main() {
     
     testrfPhoton();
     testrFresnel();
     testMPhoton();
     testSpinPhoton();
     testDropPhoton();

}

