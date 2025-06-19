# Rendering
Rendering a scene needs the following ingredients:
- `hdrimg` holds the HDR image data.
- `AbstractCamera` object defines the camera parameters.
- `PCG` is  a pseudo-random number generator used for integration and sampling.
- `renderer` is an instance of `Function` that take `World` and optionally a `PCG` object, instructing on how a ray should be traced through the scene.
- `ImageTracer` is a function that takes the `hdrimg`, `AbstractCamera`, and `renderer` (and optionally a `PCG`) to render the scene.

First we need to create an `hdrimg` object to hold the rendered image data. The `hdrimg` constructor takes the width and height of the image as parameters.
```@docs
hdrimg
```

The we can set the camera. We have two types of cameras: `Perspective` and `Orthogonal`, both subtypes of `AbstractCamera`.
```@docs
Perspective
Orthogonal
```

A `PCG` object is used for pseudo-random number generation.
```@docs
PCG
```

## Renderers
We have several renderers available, each with different complexity and quality.
```@docs
OnOff
Flat
PathTracer
PointLight
```

## Rendering process
The rendering process is initiated by calling the `ImageTracer` on a `hdrimage`. Optionally, a `PCG` object can be passed to the `ImageTracer` for antialising and stratified sampling.
```@docs
ImageTracer
```

## Saving
jujutracer provides functions to save the rendered image boht in HDR and LDR formats.
```@docs
write_pfm_image
tone_mapping
get_matrix
save_ldrimage
```

