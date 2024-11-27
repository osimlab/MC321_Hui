### MC321.ipynb: Tutorial of Monte Carlo simulation in Python modified from [mc321.c ](https://omlc.org/news/dec98/mc321/intro.html)
### MC321T.c: mc321.c with a timer.
### MC321H.chpl and photonGenerator.chpl: Chapel version of mc321.c.
- photoGenerator.chpl: a module to generate a photon
- `for` loop: CPU paprallel 
- Random generator: NPBRandom()
### MC321HR.chpl and photonGeneratorR.chpl: Chapel version of mc321.c.
- Random generator: Random()
- With `for` loop
### MC321HR_P the parallel version of MC321HR
- `for` to `for all`
- `with (+ reduce Csph, + reduce Ccyl, + reduce Cpla )` The reduction prevents race conditions or inconsistent updates, which can occur when multiple tasks try to update the same variables simultaneously in parallel code.
### Commands to run the code
- MC321T.c: `gcc -O3 --ansi MC321T.c -o MC321T -lm`
- **.chpl: `chpl **.chpl --fast`
### Simulation Comparison (1000 grids and $\mu_a$ = 0.1 $mm^{-1}$ at 1M photons and 10M photons with *)

| NP = 1million  | C | Chapel|Chapel Parallel @CPU|Chapel Parallel @GPU|Python|
|--------------|-------|-------|------|-------|-------|
|$\mu_s$ = 1 $mm^{-1}$|3.65 s|3.81 s|0.5 s/5.2s*|3s*|290 s|
|$\mu_s$ = 2 $mm^{-1}$|7.08 s|7.33 s|0.9 s/8.0s*|5.7s*|
|$\mu_s$ = 4 $mm^{-1}$|13.92 s|14.45 s|1.7s/16s*|10s*|
|$\mu_s$ = 8 $mm^{-1}$|25.54 s|28.56 s|3.46s/34s*|19s*|
|$\mu_s$ = 16 $mm^{-1}$|53.18 s|57.17 s|6.76s/70s*|37s*|

### CPU Information
Architecture:            x86_64 <br>
  CPU op-mode(s):        32-bit, 64-bit<br>
  Address sizes:         48 bits physical, 48 bits virtual<br>
  Byte Order:            Little Endian<br>
CPU(s):                  24<br>
  On-line CPU(s) list:   0-23<br>
Vendor ID:               AuthenticAMD<br>
  Model name:            AMD Ryzen Threadripper 1920X 12-Core Processor<br>
    CPU family:          23<br>
    Model:               1<br>
    Thread(s) per core:  2<br>
    Core(s) per socket:  12<br>

### Avaliable cores for calculation = 12

### mcOCT 
- Run python MC simulation with Gaussian focused light source 
- Including the refraction from the top surface 
- Save all the coordinates at each scattered position 
- Call functions throguh mcOCTFunctions
- Plot photon traces


 