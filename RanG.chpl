// Parallel random number generation using NPBRandomStream
use Random.NPBRandom;
config const seed = 61;
config const numRan = 2; // Number of random values to generate

// Initialize NPBRandomStream with a seed
var randomStream = new NPBRandomStream(real(64),seed, true);

proc add (rand: borrowed NPBRandomStream,idx:int) {
  var sum: real;
  sum = rand.getNext() + rand.getNext();
  writeln ("Sum at ",idx," is ", sum);
}

forall i in 1..numRan {
  add(randomStream,i);
}
