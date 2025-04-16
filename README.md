<div align="center">

# jujutracer
![Julia](https://img.shields.io/badge/-Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)
[![Licence](https://img.shields.io/github/license/Ileriayo/markdown-badges?style=for-the-badge)](./LICENCE.md)
![Wiki](https://img.shields.io/badge/Docs-Dev?style=for-the-badge&color=blue&link=https%3A%2F%2Fstevelonny.github.io%2Fjujutracer%2F)
![Test](https://img.shields.io/github/actions/workflow/status/stevelonny/jujutracer/Test.yml?style=for-the-badge&label=Test)

<!-- ![GitHub branch check runs](https://img.shields.io/github/check-runs/stevelonny/jujutracer/main?style=for-the-badge) -->


Simple raytracer built in julia by Boldini M., Galafassi G. and Lonardoni S. during _Calcolo Numerico per la Generazione di Immagini Fotorealistiche_ (AY 2024/25) @ UNIMI.

</div>

## Installation

Clone this repository.

```bash
git clone https://github.com/stevelonny/jujutracer.git
```

## Usage
At this stage, this software only converts a PFM image into a LDR format. 
A command line interface is provided through [`main.jl`](main.jl).
The user must provide the input file in the correct PFM format, the _a_ value and _gamma_ correction value, and the output file, which must be of the `.png` or `.jpg` extension.
```bash
julia main.jl <pfm_file> <a> <gamma> <output_file>
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
This project is licensed under the [MIT "Expat" License](LICENCE.md)
