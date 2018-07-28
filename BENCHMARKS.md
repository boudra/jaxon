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
jiffy         3.12 K      320.20 μs    ±25.14%         302 μs      607.53 μs
Jaxon         2.76 K      362.34 μs    ±24.76%         351 μs      683.16 μs
Jason         2.32 K      430.65 μs    ±19.67%         404 μs      793.99 μs
Poison        1.11 K      904.20 μs    ±18.07%         875 μs        1608 μs

Comparison:
jiffy         3.12 K
Jaxon         2.76 K - 1.13x slower
Jason         2.32 K - 1.34x slower
Poison        1.11 K - 2.82x slower

##### With input Giphy #####
Name             ips        average  deviation         median         99th %
jiffy         398.44        2.51 ms    ±11.85%        2.48 ms        3.01 ms
Jaxon         286.09        3.50 ms    ±15.27%        3.48 ms        4.87 ms
Jason         225.95        4.43 ms    ±12.23%        4.30 ms        6.42 ms
Poison         88.67       11.28 ms     ±8.83%       10.81 ms       13.98 ms

Comparison:
jiffy         398.44
Jaxon         286.09 - 1.39x slower
Jason         225.95 - 1.76x slower
Poison         88.67 - 4.49x slower

##### With input GitHub #####
Name             ips        average  deviation         median         99th %
Jaxon         1.21 K        0.83 ms    ±20.43%        0.75 ms        1.46 ms
jiffy         1.17 K        0.85 ms    ±17.99%        0.88 ms        1.18 ms
Jason         0.80 K        1.25 ms    ±15.02%        1.18 ms        2.05 ms
Poison        0.38 K        2.66 ms    ±14.85%        2.51 ms        4.18 ms

Comparison:
Jaxon         1.21 K
jiffy         1.17 K - 1.03x slower
Jason         0.80 K - 1.51x slower
Poison        0.38 K - 3.22x slower

##### With input GovTrack #####
Name             ips        average  deviation         median         99th %
jiffy           9.90      101.01 ms     ±2.63%      100.82 ms      106.37 ms
Jason           7.90      126.60 ms     ±4.01%      127.05 ms      134.57 ms
Jaxon           5.25      190.35 ms     ±2.88%      189.34 ms      209.83 ms
Poison          2.99      334.67 ms     ±1.92%      335.02 ms      350.10 ms

Comparison:
jiffy           9.90
Jason           7.90 - 1.25x slower
Jaxon           5.25 - 1.88x slower
Poison          2.99 - 3.31x slower

##### With input Issue 90 #####
Name             ips        average  deviation         median         99th %
jiffy          50.56       19.78 ms     ±7.32%       18.93 ms       23.73 ms
Jaxon          33.66       29.71 ms     ±5.41%       29.11 ms       34.84 ms
Jason           7.70      129.80 ms     ±2.70%      129.41 ms      138.48 ms
Poison          5.25      190.39 ms     ±2.45%      191.04 ms      200.13 ms

Comparison:
jiffy          50.56
Jaxon          33.66 - 1.50x slower
Jason           7.70 - 6.56x slower
Poison          5.25 - 9.63x slower

##### With input JSON Generator #####
Name             ips        average  deviation         median         99th %
jiffy         375.32        2.66 ms     ±6.12%        2.70 ms        3.22 ms
Jaxon         286.40        3.49 ms    ±13.64%        3.42 ms        4.97 ms
Jason         283.68        3.53 ms    ±14.50%        3.41 ms        5.08 ms
Poison        105.77        9.45 ms    ±10.15%        9.07 ms       12.30 ms

Comparison:
jiffy         375.32
Jaxon         286.40 - 1.31x slower
Jason         283.68 - 1.32x slower
Poison        105.77 - 3.55x slower

##### With input JSON Generator (Pretty) #####
Name             ips        average  deviation         median         99th %
jiffy         316.93        3.16 ms    ±10.92%        3.15 ms        4.30 ms
Jaxon         274.98        3.64 ms    ±13.21%        3.60 ms        4.95 ms
Jason         229.10        4.37 ms    ±14.63%        4.34 ms        6.55 ms
Poison         98.62       10.14 ms     ±9.75%        9.79 ms       13.01 ms

Comparison:
jiffy         316.93
Jaxon         274.98 - 1.15x slower
Jason         229.10 - 1.38x slower
Poison         98.62 - 3.21x slower

##### With input Pokedex #####
Name             ips        average  deviation         median         99th %
Jason         517.19        1.93 ms    ±14.00%        1.83 ms        3.06 ms
jiffy         454.35        2.20 ms    ±17.93%        2.37 ms        3.08 ms
Jaxon         379.63        2.63 ms    ±19.65%        2.53 ms        4.08 ms
Poison        138.11        7.24 ms    ±11.33%        6.95 ms        9.88 ms

Comparison:
Jason         517.19
jiffy         454.35 - 1.14x slower
Jaxon         379.63 - 1.36x slower
Poison        138.11 - 3.74x slower

##### With input UTF-8 escaped #####
Name             ips        average  deviation         median         99th %
jiffy         9.42 K       0.106 ms    ±21.51%      0.0960 ms       0.191 ms
Jaxon         7.54 K       0.133 ms    ±22.53%       0.122 ms        0.24 ms
Jason         0.90 K        1.11 ms    ±16.42%        1.07 ms        1.84 ms
Poison        0.79 K        1.27 ms    ±26.78%        1.17 ms        2.29 ms

Comparison:
jiffy         9.42 K
Jaxon         7.54 K - 1.25x slower
Jason         0.90 K - 10.45x slower
Poison        0.79 K - 11.99x slower

##### With input UTF-8 unescaped #####
Name             ips        average  deviation         median         99th %
Jaxon        20.39 K       49.04 μs    ±30.94%          45 μs          95 μs
jiffy        15.31 K       65.32 μs    ±26.86%          59 μs         126 μs
Jason         5.44 K      183.90 μs    ±22.94%         165 μs         351 μs
Poison        3.03 K      329.93 μs    ±19.50%         313 μs         610 μs

Comparison:
Jaxon        20.39 K
jiffy        15.31 K - 1.33x slower
Jason         5.44 K - 3.75x slower
Poison        3.03 K - 6.73x slower
```
