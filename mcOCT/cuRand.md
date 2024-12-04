### Cuda Random Generator
- `curand_kernel.h` is a CUDA header file provided by NVIDIA's cuRAND (CUDA Random Number Generation) library. It defines functions, types, and utilities for random number generation on the GPU, specifically in device code (within CUDA kernels).
- `curand_init(seed, idx, offset, &state[idx])` initialize RNG states based on a seed, sequence ID, and offset, enabling reproducible random sequences for each thread.    
   * `seed` The seed is used to initialize the RNG and controls the starting point of the random number sequence.
   * `idx` different idx will generate different random sequence even with the same seed.
   * `offset` can be set as 0 in the most of the time 
   * `&state[idx]` A pointer to the memory location in the state array where this thread’s RNG state will be stored.
- `curand_uniform`,`curand_normal`,`curand_normal` generate random numbers from uniform, normal, and Poisson distributions, respectively.
### CUDA Hierarchy
- When a **kernel** function ,`_global_`, is launched from the host side, execution is moved to a device where a large number of **threads** are generated.
- A **kernel** is a function written in CUDA C/C++ that runs on the GPU.<u>The kernel is executed by all threads simultaneously, but each thread can operate on different data, allowing for parallel computation.</u>
- **Thread** is the smallest unit of execution on the GPU. A group of threads forms a **block**.Threads within a block can communicate and share data via shared memory.Blocks can contain up to 1024 threads, though typical configurations use 128, 256, or 512 threads per block.A collection of blocks forms a **grid**.  
<img src= "https://github.com/osimlab/MC321_Hui/blob/main/mcOCT/Images/Kernal_Grid.jpg" alt="Example Image" width="300">  

### CUDA architecture
- **Core**: The processing unit inside GPU. Each core can handle one thread at a time.
- **Warp**: The smallest unit of scheduling on the GPU is called a warp. A warp contains 32 threads that all execute the same instruction at the same time. This is called SIMT (Single Instruction, Multiple Threads).
- **Streaming Multiprocessor (SM)**: A core unit of the GPU that contains multiple CUDA cores and other resources. Each SM manages and schedules warps and executes the threads within each block.

### Execution
- **GPU Execution Model**: Each kernel launch creates a grid of thread blocks. Blocks are assigned to SMs, which manage and execute them in parallel.
- **Warps and Divergence**: Threads within a warp execute the same instruction simultaneously, following the SIMT (Single Instruction, Multiple Threads) model. If threads within a warp diverge (i.e., take different paths due to conditional statements like if), the Streaming Multiprocessor (SM) will execute each path sequentially. This sequential handling, called **warp divergence**, can reduce performance because threads that aren’t on the active path must wait. Additionally, if one path takes significantly longer to complete, it will delay the entire warp, as all threads within the warp must finish before moving to the next instruction. Ideally, all threads in a warp should follow the same execution path to avoid divergence and maximize efficiency.
- **Memory Hierarchy**: GPUs have fast, low-latency shared memory within each SM for threads in the same block, and larger global memory for all threads. Memory access patterns impact performance significantly.

### NVDIA GPU
- An NVIDIA GPU is composed of multiple SMs (typically tens to hundreds, depending on the GPU model).Each SM has many lightweight cores (CUDA cores), each capable of executing one thread at a time
- Threads are organized into warps of 32 threads, which are the basic scheduling unit on the GPU.
- Multiple warps are grouped into a thread block. Each thread block can contain several warps (e.g., 64, 128, or more threads).
- The thread block is assigned to an SM, and all threads within the block share the SM's resources, including shared memory.
- For example, if there are 16 thread blocks, they may be distributed across the SMs based on availability.
- When there are more thread blocks than SMs, not all blocks can execute immediately. Some blocks are assigned to SMs initially
- As soon as all warps within a thread block finish their tasks, the block retires, freeing the SM to take on new blocks from the grid.   

<img src="https://github.com/osimlab/MC321_Hui/blob/main/Images/GPU_Arch.PNG" alt="GPU Architecture" width="300">   

**Ref**: Lai, Z., Sun, X., Luo, Q. et al. Accelerating multi-way joins on the GPU. The VLDB Journal 31, 529–553 (2022). https://doi.org/10.1007/s00778-021-00708-y