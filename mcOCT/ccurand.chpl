module ccurand {
  require "kernel_rng.h"; //tells the Chapel compiler to include an external file named kernel_rng.h which contains the functions that we will use .
  extern "curandState_t" type curandState_t; //telling Chapel that this type exists and we want to use it

  pragma "codegen for CPU and GPU" //paragma: instruction to the compiler that Chapel generates the  code for both CPU and GPU execution
  extern proc rng_init(seed, idx, ref state: curandState_t): void;// Declares an external procedure (function) named rng_init 

  pragma "codegen for CPU and GPU"
  extern proc rng_get(ref state: curandState_t): real;

  record CudaRng {
    var rng: curandState_t;    //rng is a variable of type curandState_t holding the state of the random number generator
    var idx: int;              //idx is an integer that holds the index of the GPU thread

    proc init(idx, seed = 1) {
      init this;               //initializes the record itself.
      rng_init(seed, idx, rng);//seed has default value of 1
    }

    inline proc ref getNext() {
      return rng_get(rng);
    }
  }
} 

