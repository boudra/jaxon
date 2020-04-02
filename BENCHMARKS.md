make: Nothing to be done for `all'.
Operating System: macOS
CPU Information: Intel(R) Core(TM) i7-6700HQ CPU @ 2.60GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.9.4
Erlang 22.1.8

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 4 s
memory time: 0 ns
parallel: 1
inputs: Blockchain, Giphy, GitHub, GovTrack, Issue 90, JSON Generator, JSON Generator (Pretty), Pokedex, UTF-8 escaped, UTF-8 unescaped, Yelp Photos
Estimated total run time: 4.40 min

Benchmarking Jason with input Blockchain...
Benchmarking Jason with input Giphy...
Benchmarking Jason with input GitHub...
Benchmarking Jason with input GovTrack...
Benchmarking Jason with input Issue 90...
Benchmarking Jason with input JSON Generator...
Benchmarking Jason with input JSON Generator (Pretty)...
Benchmarking Jason with input Pokedex...
Benchmarking Jason with input UTF-8 escaped...
Benchmarking Jason with input UTF-8 unescaped...
Benchmarking Jason with input Yelp Photos...
Benchmarking Jaxon with input Blockchain...
Benchmarking Jaxon with input Giphy...
Benchmarking Jaxon with input GitHub...
Benchmarking Jaxon with input GovTrack...
Benchmarking Jaxon with input Issue 90...
Benchmarking Jaxon with input JSON Generator...
Benchmarking Jaxon with input JSON Generator (Pretty)...
Benchmarking Jaxon with input Pokedex...
Benchmarking Jaxon with input UTF-8 escaped...
Benchmarking Jaxon with input UTF-8 unescaped...
Benchmarking Jaxon with input Yelp Photos...
Benchmarking Poison with input Blockchain...
Benchmarking Poison with input Giphy...
Benchmarking Poison with input GitHub...
Benchmarking Poison with input GovTrack...
Benchmarking Poison with input Issue 90...
Benchmarking Poison with input JSON Generator...
Benchmarking Poison with input JSON Generator (Pretty)...
Benchmarking Poison with input Pokedex...
Benchmarking Poison with input UTF-8 escaped...
Benchmarking Poison with input UTF-8 unescaped...
Benchmarking Poison with input Yelp Photos...
Benchmarking jiffy with input Blockchain...
Benchmarking jiffy with input Giphy...
Benchmarking jiffy with input GitHub...
Benchmarking jiffy with input GovTrack...
Benchmarking jiffy with input Issue 90...
Benchmarking jiffy with input JSON Generator...
Benchmarking jiffy with input JSON Generator (Pretty)...
Benchmarking jiffy with input Pokedex...
Benchmarking jiffy with input UTF-8 escaped...
Benchmarking jiffy with input UTF-8 unescaped...
Benchmarking jiffy with input Yelp Photos...
Generated output/decode_giphy_jiffy.html
Generated output/decode_github_comparison.html
Generated output/decode_github_jiffy.html
Generated output/decode_github_poison.html
Generated output/decode_issue_90_poison.html
Generated output/decode_govtrack_jason.html
Generated output/decode_blockchain_jiffy.html
Generated output/decode_govtrack_jaxon.html
Generated output/decode_govtrack_comparison.html
Generated output/decode_utf_8_escaped_jason.html
Generated output/decode_giphy_jason.html
Generated output/decode_yelp_photos_jaxon.html
Generated output/decode_giphy_comparison.html
Generated output/decode_pokedex_jaxon.html
Generated output/decode_issue_90_jiffy.html
Generated output/decode_json_generator__pretty__poison.html
Generated output/decode_yelp_photos_poison.html
Generated output/decode_blockchain_jaxon.html
Generated output/decode_govtrack_jiffy.html
Generated output/decode_issue_90_jaxon.html
Generated output/decode_yelp_photos_comparison.html
Generated output/decode_pokedex_jason.html
Generated output/decode_json_generator__pretty__jaxon.html
Generated output/decode_json_generator__pretty__jason.html
Generated output/decode_pokedex_jiffy.html
Generated output/decode_json_generator__pretty__jiffy.html
Generated output/decode_json_generator_comparison.html
Generated output/decode_utf_8_escaped_jiffy.html
Generated output/decode_utf_8_unescaped_jiffy.html
Generated output/decode_json_generator__pretty__comparison.html
Generated output/decode_json_generator_jason.html
Generated output/decode_utf_8_escaped_poison.html
Generated output/decode_blockchain_jason.html
Generated output/decode_github_jaxon.html
Generated output/decode_issue_90_comparison.html
Generated output/decode_giphy_poison.html
Generated output/decode_utf_8_unescaped_jaxon.html
Generated output/decode_utf_8_unescaped_jason.html
Generated output/decode_govtrack_poison.html
Generated output/decode_json_generator_poison.html
Generated output/decode_utf_8_unescaped_comparison.html
Generated output/decode_blockchain_comparison.html
Generated output/decode_yelp_photos_jiffy.html
Generated output/decode_json_generator_jaxon.html
Generated output/decode_issue_90_jason.html
Generated output/decode_pokedex_poison.html
Generated output/decode.html
Generated output/decode_yelp_photos_jason.html
Generated output/decode_blockchain_poison.html
Generated output/decode_json_generator_jiffy.html
Generated output/decode_giphy_jaxon.html
Generated output/decode_utf_8_escaped_jaxon.html
Generated output/decode_utf_8_unescaped_poison.html
Generated output/decode_pokedex_comparison.html
Generated output/decode_github_jason.html
Generated output/decode_utf_8_escaped_comparison.html
Opened report using open

##### With input Blockchain #####
Name             ips        average  deviation         median         99th %
jiffy         3.99 K      250.34 μs    ±41.99%         220 μs      632.77 μs
Jaxon         3.91 K      255.58 μs    ±24.79%         256 μs         444 μs
Jason         2.22 K      449.80 μs     ±9.34%         443 μs      628.00 μs
Poison        1.37 K      730.54 μs    ±12.59%         730 μs      996.44 μs

Comparison: 
jiffy         3.99 K
Jaxon         3.91 K - 1.02x slower +5.23 μs
Jason         2.22 K - 1.80x slower +199.46 μs
Poison        1.37 K - 2.92x slower +480.20 μs

##### With input Giphy #####
Name             ips        average  deviation         median         99th %
jiffy         540.15        1.85 ms    ±15.37%        1.75 ms        2.84 ms
Jaxon         404.01        2.48 ms    ±12.98%        2.53 ms        3.15 ms
Jason         226.54        4.41 ms     ±8.38%        4.40 ms        5.43 ms
Poison        119.52        8.37 ms     ±8.40%        8.46 ms        9.85 ms

Comparison: 
jiffy         540.15
Jaxon         404.01 - 1.34x slower +0.62 ms
Jason         226.54 - 2.38x slower +2.56 ms
Poison        119.52 - 4.52x slower +6.52 ms

##### With input GitHub #####
Name             ips        average  deviation         median         99th %
jiffy         1.64 K        0.61 ms    ±22.27%        0.59 ms        1.07 ms
Jaxon         1.63 K        0.61 ms    ±22.30%        0.62 ms        0.90 ms
Jason         0.76 K        1.32 ms     ±6.82%        1.31 ms        1.69 ms
Poison        0.47 K        2.11 ms     ±6.68%        2.10 ms        2.64 ms

Comparison: 
jiffy         1.64 K
Jaxon         1.63 K - 1.01x slower +0.00532 ms
Jason         0.76 K - 2.17x slower +0.71 ms
Poison        0.47 K - 3.47x slower +1.50 ms

##### With input GovTrack #####
Name             ips        average  deviation         median         99th %
Jaxon          13.18       75.86 ms     ±7.25%       74.54 ms      104.00 ms
jiffy          11.73       85.22 ms     ±9.80%       83.04 ms      108.68 ms
Jason           8.03      124.47 ms     ±2.79%      124.55 ms      131.95 ms
Poison          3.98      250.99 ms     ±1.84%      249.49 ms      262.96 ms

Comparison: 
Jaxon          13.18
jiffy          11.73 - 1.12x slower +9.36 ms
Jason           8.03 - 1.64x slower +48.61 ms
Poison          3.98 - 3.31x slower +175.13 ms

##### With input Issue 90 #####
Name             ips        average  deviation         median         99th %
Jaxon         146.38        6.83 ms     ±4.87%        6.82 ms        7.71 ms
jiffy          56.02       17.85 ms    ±11.23%       17.34 ms       29.59 ms
Poison          6.93      144.35 ms     ±2.86%      144.43 ms      152.80 ms
Jason           6.69      149.45 ms     ±2.64%      149.25 ms      157.54 ms

Comparison: 
Jaxon         146.38
jiffy          56.02 - 2.61x slower +11.02 ms
Poison          6.93 - 21.13x slower +137.52 ms
Jason           6.69 - 21.88x slower +142.62 ms

##### With input JSON Generator #####
Name             ips        average  deviation         median         99th %
jiffy         551.77        1.81 ms    ±11.97%        1.81 ms        2.35 ms
Jaxon         442.81        2.26 ms    ±11.80%        2.39 ms        2.83 ms
Jason         271.37        3.69 ms     ±5.46%        3.67 ms        4.39 ms
Poison        151.77        6.59 ms     ±5.38%        6.52 ms        7.64 ms

Comparison: 
jiffy         551.77
Jaxon         442.81 - 1.25x slower +0.45 ms
Jason         271.37 - 2.03x slower +1.87 ms
Poison        151.77 - 3.64x slower +4.78 ms

##### With input JSON Generator (Pretty) #####
Name             ips        average  deviation         median         99th %
jiffy         445.41        2.25 ms     ±8.57%        2.22 ms        2.79 ms
Jaxon         424.23        2.36 ms    ±11.55%        2.47 ms        2.94 ms
Jason         228.94        4.37 ms     ±5.31%        4.34 ms        5.16 ms
Poison        138.12        7.24 ms     ±5.10%        7.25 ms        8.24 ms

Comparison: 
jiffy         445.41
Jaxon         424.23 - 1.05x slower +0.112 ms
Jason         228.94 - 1.95x slower +2.12 ms
Poison        138.12 - 3.22x slower +4.99 ms

##### With input Pokedex #####
Name             ips        average  deviation         median         99th %
jiffy         620.51        1.61 ms     ±8.18%        1.58 ms        2.21 ms
Jaxon         565.03        1.77 ms    ±17.35%        1.59 ms        2.48 ms
Jason         467.76        2.14 ms     ±9.41%        2.10 ms        2.72 ms
Poison        203.60        4.91 ms     ±5.70%        4.91 ms        5.83 ms

Comparison: 
jiffy         620.51
Jaxon         565.03 - 1.10x slower +0.158 ms
Jason         467.76 - 1.33x slower +0.53 ms
Poison        203.60 - 3.05x slower +3.30 ms

##### With input UTF-8 escaped #####
Name             ips        average  deviation         median         99th %
jiffy        12.86 K       77.79 μs    ±66.41%          75 μs         141 μs
Jaxon         7.82 K      127.86 μs    ±25.18%         125 μs         204 μs
Poison        1.32 K      758.93 μs    ±13.38%         727 μs     1090.20 μs
Jason         1.17 K      852.19 μs    ±11.19%         832 μs     1207.00 μs

Comparison: 
jiffy        12.86 K
Jaxon         7.82 K - 1.64x slower +50.08 μs
Poison        1.32 K - 9.76x slower +681.14 μs
Jason         1.17 K - 10.96x slower +774.41 μs

##### With input UTF-8 unescaped #####
Name             ips        average  deviation         median         99th %
Jaxon        58.20 K       17.18 μs   ±127.32%          15 μs          34 μs
jiffy        16.95 K       58.99 μs    ±63.83%          56 μs         103 μs
Jason         5.21 K      192.10 μs    ±14.51%         185 μs         306 μs
Poison        4.00 K      250.20 μs    ±12.93%         236 μs         379 μs

Comparison: 
Jaxon        58.20 K
jiffy        16.95 K - 3.43x slower +41.81 μs
Jason         5.21 K - 11.18x slower +174.92 μs
Poison        4.00 K - 14.56x slower +233.01 μs

##### With input Yelp Photos #####
Name             ips        average  deviation         median         99th %
jiffy           1.59         0.63 s    ±11.82%         0.60 s         0.80 s
Jaxon           1.09         0.92 s    ±37.42%         0.70 s         1.38 s
Jason           0.89         1.12 s     ±8.43%         1.08 s         1.25 s
Poison          0.35         2.89 s     ±3.23%         2.89 s         2.96 s

Comparison: 
jiffy           1.59
Jaxon           1.09 - 1.47x slower +0.29 s
Jason           0.89 - 1.78x slower +0.49 s
Poison          0.35 - 4.61x slower +2.27 s
