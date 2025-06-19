# REPL Examples

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