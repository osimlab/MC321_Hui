use GPU;
use ccurand;
var randomValue: real;

type RNG = CudaRng; // Use the CudaRng class
on here.gpus[0] {
   writeln(here);
   var randomValue: [0..20] real;
   @assertOnGpu // Ensure that the following code runs on the GPU. Need to before the loop
   foreach i in 0..20 {
      var rng = new RNG(i+10);
   // Generate and print a random number
      randomValue[i] = rng.getNext(); // Generate a random number
   }
   writeln("Random Value: ", randomValue);
}

