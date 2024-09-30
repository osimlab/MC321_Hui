### MC321.ipynb: Tutorial of Monte Carlo simulation in Python modified from [mc321.c ](https://omlc.org/news/dec98/mc321/intro.html)
### MC321T.c: mc321.c with a timer.
### MC321H.chpl and photonGenerator.chpl: Chapel version of mc321.c.
- photoGenerator.chpl: a module to generate a photon
- `for` to `for all` : CPU paprallel 
- Random generator: NPBRandom
### Simulation Comparison (1000 grids and $\mu_a$ = 0.1 $mm^{-1}$)

| NP = 1million  | C | Chapel|Chapel@CPU|Chapel@GPU|Python|
|--------------|-------|-------|------|-------|-------|
|$\mu_s$ = 1 $mm^{-1}$|6.9 s|28.9 s|5.5 s|NA|290 s|
|$\mu_s$ = 2 $mm^{-1}$|13.4 s|56.13 s|10.6 s|NA|
|$\mu_s$ = 4 $mm^{-1}$|25.9 s|103 s|21.0 s|NA|
|$\mu_s$ = 8 $mm^{-1}$|50.7 s|208 s|41.23 s|NA|
|$\mu_s$ = 16 $mm^{-1}$|101.9 s|416 s|82.12 s|NA|

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



 