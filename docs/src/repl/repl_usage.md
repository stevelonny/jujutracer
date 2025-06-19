# REPL Usage
--------
jujutracer exposes various function and structs that can be used in the repl to create scenes, render them and save the results.

## Quick Start

A quick start to create a scene and render it is as follows:

```shell
julia -t auto
```

```julia
using Pkg
Pkg.activate(".")
using jujutracer
```

**Create some shapes.** They must have materials and transfomations defined.
A material can be defined as emissive or not by defining its color, and with a diffusive or mirror-like behavior.

```julia
mat_ground = Material(UniformPigment(RGB(0.0, 0.0, 0.0)), DiffusiveBRDF(CheckeredPigment(RGB(0.1, 0.1, 0.1), RGB(0.2, 0.2, 0.2), 8, 8)))
mat_sphere = Material(UniformPigment(RGB(0.0, 0.0, 0.0)), SpecularBRDF(UniformPigment(RGB(1.0, 1.0, 1.0))))
mat_sky = Material(ImagePigment("asset/sky.pfm"), DiffusiveBRDF(UniformPigment(RGB(0.1, 0.1, 0.1))))

ground = Plane(mat_ground)
sphere = Sphere(mat_sphere, Scaling(0.5, 0.5, 0.5))
sky = Sphere(mat_sky, Scaling(10.0, 10.0, 10.0))
```

Prepare the world with the shapes.
```julia
shapes = Vector{AbstractShape}()
push!(shapes, ground)
push!(shapes, sphere)

world = World(shapes)
```

**Action!** Create a camera and a renderer.
```julia
# Prepare the hdr image
hdrimage = HDRImage(800, 600)
# Set the camera
cam = Perspective(d=2.0, t=(-1.5, 0.0, 1.0) ⊙ Ry(-π / 10.0))
# Prepare the renderer
ImgTr = ImageTracer(hdr, cam)
pcg = PCG()
path = PathTracer(world, gray, pcg, 2, 5, 2)
# Start the rendering
ImgTr(path, pcg)
```

**Save the result.** 
```julia
# Save the HDR image
write_pfm_image(hdr, pfm_output)
# Save the LDR image
toned_img = tone_mapping(hdr; a=0.5, lum=0.5, γ=1.3)
save_ldrimage(get_matrix(toned_img), png_output)
```

## Contents
```@contents
Pages = Main.SCENE_USAGE_SUBSECTION
Depth = 5
```
