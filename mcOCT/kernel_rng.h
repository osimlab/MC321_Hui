#include <curand_kernel.h>
// _device_ only be called  from GPU
// _host_ only be called from CPU
 __device__ static inline void rng_init(int seed, int idx, curandState_t* state) {
  curand_init(seed, idx, 0, state);
}

__device__ static inline double rng_get(curandState_t* state) {
  double ret = curand_uniform_double(state);
  //printf("%f\n", ret);
  return ret;
}
// calling _host_ will report error
__host__ static inline void rng_init(int idx, int seed, curandState_t* state) {
  printf("error\n");
}

__host__ static inline float rng_get(curandState_t* state) {
  printf("error\n");
  return 0.0;
}
