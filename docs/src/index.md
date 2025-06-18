# jujutracer documentation

Documentation for the package jujutracer.

# Main Usage
The main feature of this project is developed in `interpreter.jl` <!--[`interpreter.jl`](https://github.com/stevelonny/jujutracer/blob/main/interpreter.jl)--> which, from a `scene.txt` file, is able to parse the construction of the desired scene. The rendering of the scene it's not completly yield from the scene file, some information, like the type of renderer, need to be specified at the time of the excecution.

Follows some instruction for writing a correct `scene.txt`

## Supporting types
Some type do not correspond to a variable and needs to be yield directly in the definition of the variables. Some example:
- color: `< r, g, b >`
- pigment: `checkered(<color1>, <color2>, <n_subdivisions>)`
- brdf: `diffuse(<pigment>)`
- tranformation: `translation([x, y, z])`

## Variables
Here some example of variable supported and their definition:
- float: `float name(<value>)`
    ```text
    float pi(3.141592653589793)
    ```
- material: `material mat_name(<brdf>, <emission_pigment>)`
    ```text
    material mat_name(diffuse(uniform(< 0.1, 0.7, 0.3>)),
                      image("asset/sky.pfm")
                      )
    ```
- shapes: `shape_type shape_name(<material>, <transformation>)`
    ```text
    cone cone_name(mat_name, rotation_x(pi))
    ```

The declaration of the variables needs to be ordered.

## World and camera
Once the shapes have been definied need to add them to the world:
```text
add cone_name
```
The last, but not list, thing to be definied in the `scene.txt` is the camera:
```text
# perspective
camera(perspective, <tranformation>, <aspect_ratio>, <screen_distance>)

# orthogonal
camera(orthogonal, <tranformation>, <aspect_ratio>)
```

## Execution arguments
As said before, the parameter of rendering of the image need to be specified at the time of the execution. Follows the types with their keyword and default values:
- Image Width: "--width" or "-W"; default = 640
- Image Heigth: "--depth" or "-H"; default = 360
- Output image file: "--output" or "-o"; default = "output.png"
- Output PFM file: "--pfm_output" or "-p"; default = "output.pfm"
- Renderer: "--renderer" or "-r"; default = "path_traacer"
- Antialiasing: "--antialiasing" or "-a"; default = 2

The supported type of renderer are Path Tracing ("path_tracer"), Point-light Tracing ("point"), Flat renderer ("flat") and On-Off Renderer ("on_off"). If Path Tracing is chosen some other arguments can be set for the execution:
- Number of rays fired at each intersection: "--n_rays"; default = 3
- Maximum reachable ray depth (even for Point-Light Tracing): "--depth"; default = 3
- Russian roulet level: "--russian"; default = 2

The final usage of the script is:
```bash
julia interpreter.jl scene.txt --keyword key
```

# Other usage

## PFM converter
Convert a `PFM` file into a LDR format such as `.png` or `.jpg`. Need ``a`` and ``\gamma`` values specified.

```bash
julia main.jl <pfm_file> <a> <gamma> <output_file>
```

## First Demo
A demo scene is provided with the `demo.jl` script. The scene is composed by 8 spheres with a uniform pigment positioned on the edges of a cube, and 2 checkered spheres placed in the middle of two adiacent faces.
The user must provide the output filename, which will be used to saved the output image in both `.pfm` and `.png` formats, the width and height of the image and the camera angle.
```bash
julia demo.jl <output_file> <width> <height> <cam_angle>
```

## CSG Demo
A demo scene is provided for showcasing Constructive Solid Geometry capabilities. `demoCSG.jl` provides a perspective view of a few operations between 2 spheres and a cone: union between 3 shapes, union of 2 spheres from which is substracted the cone, and finally the intersection of all 3 shapes. Rotations are applied to the CSG shapes.

Usage of the script is similar to `demo.jl`:
```bash
julia demoCSG.jl <output_file> <width> <height> <cam_angle>
```

## Demo Path
A demo scene is provided for showcasing the path-tracer algorithm implemented with `demoPath.jl`. The scene is composed by a checkered diffusive plane used as a floor, which cut in half a reflective red sphere. Hovering the floor there is a checkered diffusive sphere, and a bright sky is provided.

Usage of the script is the same:
```bash
julia demoPath.jl <output_file> <width> <height> <cam_angle>
```

## Demo All
A demo script implmenting CSGs, AABBs, meshes, and flat shape is provided with `demoAll.jl`. The script can be modified with the preferred method of rendering, resolution, antialiasing and path tracing parameters. With "depth" renderer a BVH tree is implemented.

The usage of the script is:
```bash
julia demoAll.jl
```
