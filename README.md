### MC321.ipynb: Tutorial of Monte Carlo simulation in Python modified from [mc321.c ](https://omlc.org/news/dec98/mc321/intro.html)
### MC321T.c: mc321.c with a timer.
### MC321H.chpl and photonGenerator.chpl: Chapel version of mc321.c 
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






 