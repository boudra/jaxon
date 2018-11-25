```
Operating System: macOS"
CPU Information: Intel(R) Core(TM) i7-6700HQ CPU @ 2.60GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.6.3
Erlang 20.2.2

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 μs
parallel: 1
inputs: Blockchain, Giphy, GitHub, GovTrack, Issue 90, JSON Generator, JSON Generator (Pretty), Pokedex, UTF-8 escaped, UTF-8 unescaped
Estimated total run time: 4.67 min

##### With input Blockchain #####
Name             ips        average  deviation         median         99th %
Jaxon         3.29 K      303.66 μs    ±21.44%         297 μs      465.08 μs
jiffy         3.23 K      309.55 μs    ±21.07%         298 μs         493 μs
Jason         2.47 K      404.95 μs    ±11.30%         399 μs         547 μs
Poison        1.20 K      836.91 μs    ±10.18%         836 μs        1050 μs

Comparison:
Jaxon         3.29 K
jiffy         3.23 K - 1.02x slower
Jason         2.47 K - 1.33x slower
Poison        1.20 K - 2.76x slower

##### With input Giphy #####
Name             ips        average  deviation         median         99th %
jiffy         393.99        2.54 ms     ±3.84%        2.53 ms        2.73 ms
Jaxon         347.24        2.88 ms    ±17.58%        2.52 ms        4.20 ms
Jason         241.14        4.15 ms     ±5.19%        4.17 ms        4.68 ms
Poison        105.56        9.47 ms     ±2.61%        9.43 ms       10.14 ms

Comparison:
jiffy         393.99
Jaxon         347.24 - 1.13x slower
Jason         241.14 - 1.63x slower
Poison        105.56 - 3.73x slower

##### With input GitHub #####
Name             ips        average  deviation         median         99th %
Jaxon         1.38 K        0.73 ms    ±12.17%        0.69 ms        1.05 ms
jiffy         1.17 K        0.86 ms    ±17.65%        0.87 ms        1.19 ms
Jason         0.86 K        1.16 ms    ±13.89%        1.14 ms        1.37 ms
Poison        0.40 K        2.50 ms     ±6.22%        2.49 ms        3.02 ms

Comparison:
Jaxon         1.38 K
jiffy         1.17 K - 1.18x slower
Jason         0.86 K - 1.59x slower
Poison        0.40 K - 3.44x slower

##### With input GovTrack #####
Name             ips        average  deviation         median         99th %
jiffy          10.09       99.10 ms     ±2.37%       99.00 ms      104.58 ms
Jason           8.25      121.24 ms     ±3.95%      121.61 ms      133.06 ms
Jaxon           5.62      177.87 ms     ±1.98%      177.41 ms      191.61 ms
Poison          3.04      328.48 ms     ±4.62%      320.33 ms      361.28 ms

Comparison:
jiffy          10.09
Jason           8.25 - 1.22x slower
Jaxon           5.62 - 1.79x slower
Poison          3.04 - 3.31x slower

##### With input Issue 90 #####
Name             ips        average  deviation         median         99th %
jiffy          52.92       18.90 ms     ±3.71%       18.74 ms       22.61 ms
Jaxon          45.38       22.04 ms     ±2.86%       21.92 ms       25.20 ms
Jason           7.97      125.43 ms     ±1.88%      125.42 ms      138.12 ms
Poison          5.55      180.09 ms     ±1.14%      179.87 ms      186.89 ms

Comparison:
jiffy          52.92
Jaxon          45.38 - 1.17x slower
Jason           7.97 - 6.64x slower
Poison          5.55 - 9.53x slower

##### With input JSON Generator #####
Name             ips        average  deviation         median         99th %
jiffy         374.65        2.67 ms     ±6.72%        2.72 ms        2.93 ms
Jason         324.19        3.09 ms     ±7.35%        3.00 ms        3.68 ms
Jaxon         312.02        3.21 ms     ±5.40%        3.19 ms        3.72 ms
Poison        129.21        7.74 ms     ±3.23%        7.70 ms        8.75 ms

Comparison:
jiffy         374.65
Jason         324.19 - 1.16x slower
Jaxon         312.02 - 1.20x slower
Poison        129.21 - 2.90x slower

##### With input JSON Generator (Pretty) #####
Name             ips        average  deviation         median         99th %
Jaxon         360.06        2.78 ms     ±5.47%        2.74 ms        3.27 ms
jiffy         330.49        3.03 ms     ±8.56%        3.05 ms        3.72 ms
Jason         268.88        3.72 ms     ±4.11%        3.69 ms        4.35 ms
Poison        117.45        8.51 ms     ±4.64%        8.44 ms       10.19 ms

Comparison:
Jaxon         360.06
jiffy         330.49 - 1.09x slower
Jason         268.88 - 1.34x slower
Poison        117.45 - 3.07x slower

##### With input Pokedex #####
Name             ips        average  deviation         median         99th %
Jason         549.79        1.82 ms     ±6.76%        1.79 ms        2.22 ms
jiffy         457.09        2.19 ms    ±16.84%        2.37 ms        2.69 ms
Jaxon         431.86        2.32 ms     ±8.12%        2.36 ms        2.84 ms
Poison        176.66        5.66 ms     ±3.88%        5.63 ms        6.42 ms

Comparison:
Jason         549.79
jiffy         457.09 - 1.20x slower
Jaxon         431.86 - 1.27x slower
Poison        176.66 - 3.11x slower

##### With input UTF-8 escaped #####
Name             ips        average  deviation         median         99th %
jiffy        10.04 K      0.0996 ms    ±15.52%      0.0960 ms       0.159 ms
Jaxon         8.89 K       0.113 ms    ±10.89%       0.110 ms       0.168 ms
Jason         0.98 K        1.02 ms    ±10.04%        1.03 ms        1.27 ms
Poison        0.96 K        1.05 ms     ±9.16%        1.04 ms        1.29 ms

Comparison:
jiffy        10.04 K
Jaxon         8.89 K - 1.13x slower
Jason         0.98 K - 10.26x slower
Poison        0.96 K - 10.49x slower

##### With input UTF-8 unescaped #####
Name             ips        average  deviation         median         99th %
Jaxon        28.92 K       34.59 μs    ±29.30%          33 μs          67 μs
jiffy        15.83 K       63.19 μs    ±20.86%          60 μs         113 μs
Jason         5.70 K      175.42 μs    ±17.81%         160 μs         287 μs
Poison        3.23 K      309.96 μs    ±10.27%         308 μs         418 μs

Comparison:
Jaxon        28.92 K
jiffy        15.83 K - 1.83x slower
Jason         5.70 K - 5.07x slower
Poison        3.23 K - 8.96x slower
```
