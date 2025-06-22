# Interpreter
Once a scene is defined in a text file such as `scene.txt`, it can be interpreted and rendered using the `interpreter.jl` script. This script is designed to read the scene file, parse its contents, and execute the rendering process based on the specified parameters.

Parameters available are:

| Parameter                 | Keyword(s)            | Default Value                                         | Description                               |
|---------------------------|-----------------------|-------------------------------------------------------|-------------------------------------------|
| Image Width               | `--width`, `-W`       | 640                                                   | Width of the output image                 |
| Image Height              | `--height`, `-H`      | round(width / camera.a_ratio)                         | Height of the output image                |
| Output Image              | `--output`, `-o`      | `<scene_filename>_<renderer>_<width>x<height>.png`    | Output image file name                    |
| Output PFM                | `--pfm_output`, `-p`  | `<scene_filename>_<renderer>_<width>x<height>.pfm`    | Output PFM file name                      |
| Renderer                  | `--renderer`, -`r`    | path_tracer                                           | Rendering algorithm                       |
| Antialiasing              | `--antialiasing`, `-a`| 2                                                     | Antialiasing level                        |
| Rays per Hit              | `--n_rays`            | 3                                                     | Rays fired at each intersection           |
| Max Ray Depth             | `--depth`             | 3                                                     | Maximum ray recursion depth               |
| Russian Roulette          | `--russian`           | 2                                                     | Russian roulette level                    |
| Overriden Variables       | `-v [var1 1.0...]`    | None                                                  | Override scene variables                  |
| Seed for PCG              | `--seed`              | 42                                                    | Seed for the random number generator      |
| Sequence number for PCG   | `--sequence`          | 54                                                    | Unique sequence identifier for the RNG    |

The name of the scene file must be provided as the first argument when running the script. All other parameters are optional and will use their default values if not specified.

The final usage of the script is:
```shell
julia -t auto interpreter.jl scene.txt
```
Another example of usage with custom parameters:
```powershell
julia -t 4 .\interpreter.jl .\scenes\tree.txt -W 900 -H 1600 -a 4 --n_rays 4 --depth 3 -o .\Images\tree_path_1600x900_4_4_3_2.png -p .\Images\tree_path_900x1600_4_4_3_2.pfm
```