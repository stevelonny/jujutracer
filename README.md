# jujutracer

Simple Raytracer built in julia by Boldini M., Galafassi G. and Lonardoni S. during _Calcolo Numerico per la Generazione di Immagini Fotorealistiche_ (AY 2024/25) @ UNIMI.

## Installation

Clone this repository.

```bash
git clone https://github.com/stevelonny/jujutracer.git
```

## Usage
At this stage, this software only convert a PFM image into a LDR format. 
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
