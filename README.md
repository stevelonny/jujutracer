<div align="center">

# jujutracer
![Julia](https://img.shields.io/badge/-Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)
[![Licence](https://img.shields.io/github/license/Ileriayo/markdown-badges?style=for-the-badge)](./LICENCE.md)
[![Wiki](https://img.shields.io/badge/Docs-Dev?style=for-the-badge&color=blue&link=https%3A%2F%2Fstevelonny.github.io%2Fjujutracer%2Fdev)](https://stevelonny.github.io/jujutracer/dev/)
[![Test](https://img.shields.io/github/actions/workflow/status/stevelonny/jujutracer/Test.yml?style=for-the-badge&label=Test&link=https%3A%2F%2Fgithub.com%2Fstevelonny%2Fjujutracer%2Factions%2Fworkflows%2FTest.yml)](https://github.com/stevelonny/jujutracer/actions/workflows/Test.yml)

<!-- ![GitHub branch check runs](https://img.shields.io/github/check-runs/stevelonny/jujutracer/main?style=for-the-badge) -->


Simple raytracer built in julia by Boldini M., Galafassi G. and Lonardoni S. during _Calcolo Numerico per la Generazione di Immagini Fotorealistiche_ (AY 2024/25) @ UNIMI.

</div>

## Installation

Clone this repository.

```bash
git clone https://github.com/stevelonny/jujutracer.git
```

## Usage

### Conversion PFM -> LDR formats
The user must provide the input file in the correct PFM format, the _a_ value and _gamma_ correction value, and the output file, which must be of the `.png` or `.jpg` extension.
```bash
julia main.jl <pfm_file> <a> <gamma> <output_file>
```

### Demo version
A demo scene is provided with the `demo.jl` script. The scene is composed by 8 spheres with a uniform pigment positioned on the edges of a cube, and 2 checkered spheres placed in the middle of two adiacent faces.
The user must provide the output filename, which will be used to saved the output image in both `.pfm` and `.png` formats, the width and height of the image and the camera angle.
```bash
julia demo.jl <output_file> <width> <height> <cam_angle>
```

#### CSG Showacase
A demo scene is provided for showcasing Constructive Solid Geometry capabilities. `demoCSG.jl` provides a perspective view of a few operations between 3 identical spheres translated along the three axis: union between 3 spheres, union of 2 spheres from which is substracted a 3rd one, and finally the intersection of all 3 spheres. Rotations are applied to the CSG shapes. Usage of the script is similar to `demo.jl`.
```bash
julia demoCSG.jl <output_file> <width> <height> <cam_angle>
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
This project is licensed under the [MIT "Expat" License](LICENCE.md)
