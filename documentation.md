# Usage
The main feature of this project is developed in [`interpreter.jl`](interpreter.jl) which, from a `scene.txt` file, is able to parse the construction of the desired scene. The rendering of the scene it's not completly yield from the scene file, some information, like the type of renderer, need to be specified at the time of the excecution.

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
