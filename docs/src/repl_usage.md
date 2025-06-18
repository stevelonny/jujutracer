# REPL Usage
jujutracer exposes various function and structs that can be used in the repl to create scenes, render them and save the results.

The flow is the following:
1. **World definition**: Create materials, shapes, and add them to the world.
2. **Rendering**: Set the camera type, position, and other parameters.

## World Definition
To define a scene, you will need to place some shapes in the world.
All shapes are a subtype of [`AbstractShape`](). Moreover, shapes which are considerer "solid" or "closed" are a subtype of [`AbstractSolid`]().
In addition to standard shapes there are auxiliary shapes such as [`AABB`]() and [`BVHShape`]() which are used as acceleration structures.

Every shape needs a material and a transformation.

### Materials
Materials are defined in a concrete type:
```@docs
Material
```
#### Pigments
The emission of the material can be defined as a pigment, which is a subtype of [`AbstractPigment`](). 

They are based on the ColorTypes.jl package, of which we use the `RGB` type.

There are three types of pigments:
```@docs
UniformPigment
CheckeredPigment
ImagePigment
```

#### BRDFs
The BRDF of the material is defined as a subtype of [`AbstractBRDF`](). The available BRDFs are
```@docs
DiffusiveBRDF
SpecularBRDF
```

A complete material can be defined as follows:
```julia
mat = Material(
    ImagePigment("asset/sky.pfm"),
    DiffuseBRDF(UniformPigment(RGB(0.1, 0.7, 0.3)))
)
```

### Transformations
Transformations are defined as a subtype of [`AbstractTransformation`](). They are structs thah hold a transformation matrix and its inverse for fast change of basis from world to local coordinates.
The available transformations are:
```@docs
Transformation
Translation
Rx
Ry
Rz
Scaling
```

### Shapes
Shapes are defined as a subtype of [`AbstractShape`](). There are two categories of shapes:, the ones that can be used in CSG operations and the ones that cannot, such as flat shapes.
#### Water-tight Shapes
```@docs
Sphere
Box
Cone
Cylinder
```
##### CSG Shapes
Set operations are defined as methods on the [`AbstractSolid`]()` type. The available operations are:
```@docs
CSGUnion
CSGIntersection
CSGDifference
```

#### Flat Shapes
```@docs
Plane
Triangle
Parallelogram
Rectangle
Circle
```


#### Auxiliary Shapes
Auxiliary shapes are used for acceleration structures. They are defined as a subtype of [`AbstractShape`]().
```@docs
AABB
BVHShape
```

### Light Sources
Light sources are defined as a subtype of [`AbstractLight`](). They are used to illuminate the scene.
```@docs
LightSource
SpotLight
```

### BVH and AABB

### World
Define a vector of shapes

Define a vector of lights


## Rendering

### Camera

### Hdrimage, Imgtr

### Renderer

