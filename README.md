<div align="center">

# jujutracer
![Julia](https://img.shields.io/badge/-Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)
[![Licence](https://img.shields.io/github/license/Ileriayo/markdown-badges?style=for-the-badge)](./LICENCE.md)
[![Docs stable](https://img.shields.io/badge/docs-stable-blue?style=for-the-badge&labelColor=grey&color=blue)](https://stevelonny.github.io/jujutracer/stable/)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue?style=for-the-badge&labelColor=grey&color=blue)](https://stevelonny.github.io/jujutracer/dev/)
[![Test](https://img.shields.io/github/actions/workflow/status/stevelonny/jujutracer/TestOnMain.yml?branch=main&style=for-the-badge&label=test
)](https://github.com/stevelonny/jujutracer/actions/workflows/TestOnMain.yml)

<!-- ![GitHub branch check runs](https://img.shields.io/github/check-runs/stevelonny/jujutracer/main?style=for-the-badge) -->


Simple raytracer built in julia by Boldini M., Galafassi G. and Lonardoni S. during _Calcolo Numerico per la Generazione di Immagini Fotorealistiche_ (AY 2024/25) @ UNIMI.

</div>

## Installation

Clone this repository.

```bash
git clone https://github.com/stevelonny/jujutracer.git
```

Then activate the environment and instantiate the dependencies.

```bash
cd jujutracer
julia --project=.
```

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

Enjoy the code! Either use the REPL or use the scene definition language to define your scene and render it as per [documentation](https://stevelonny.github.io/jujutracer/stable/).


## Usage

### Renderings
The code can be used either as a library in the REPL as showcased in the [scripts](/scripts) folder, or with the provided [`interpreter`](/interpreter.jl) to define scenes such as the ones provided in the [`scenes`](/scenes) folder.

For further details on how REPL and scene definition usage, please refer to the [documentation](https://stevelonny.github.io/jujutracer/stable/).

### Conversion PFM -> LDR formats
The user must provide the input file in the correct PFM format, the _a_ value and _gamma_ correction value, and the output file, which must be of the `.png` or `.jpg` extension.
```bash
julia main.jl <pfm_file> <a> <gamma> <output_file>
```

### Multi-thread support
*See issue [#22](https://github.com/stevelonny/jujutracer/issues/22)*

The code leverages multi-threading in a clean way simply by parallelizing each ray fired using the `@threads` keyword.
<!-- The following results have been obtained on a Windows 10 machine powered by an i5-10300H using julia 1.11.4, running both demo scenes illustrated previously at a resolution of `1920x1080`.
```powershell
C:\Users\steve\projects\jujutracer> julia -t 1 bench.jl
  Activating project at `C:\Users\steve\projects\jujutracer`
Number of threads: 1
Benchmarking demo...
  23.791 s (849584834 allocations: 40.53 GiB)
Benchmarking demoCSG...
  35.361 s (1248189420 allocations: 59.90 GiB)
C:\Users\steve\projects\jujutracer> julia -t 8 bench.jl
  Activating project at `C:\Users\steve\projects\jujutracer`
Number of threads: 8
Benchmarking demo...
  9.524 s (849584869 allocations: 40.53 GiB)
Benchmarking demoCSG...
  15.422 s (1248189455 allocations: 59.90 GiB)
C:\Users\steve\projects\jujutracer> 
``` -->

To leverage multi-thread, launch `julia` with the correct flag `t` and the number of threads to be assigned (or the `auto` keyword).
```bash
julia -t auto demo.jl <output_file> <width> <height> <cam_angle>
julia -t auto demoCSG.jl <output_file> <width> <height> <cam_angle>
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
This project is licensed under the [MIT "Expat" License](LICENCE.md)
