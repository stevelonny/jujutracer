# World

To define a scene, you will need to place some shapes in the world.
All shapes are a subtype of [`AbstractShape`](). Moreover, shapes which are considerer "solid" or "closed" are a subtype of [`AbstractSolid`]().
In addition to standard shapes there are auxiliary shapes such as [`AABB`]() and [`BVHShape`]() which are used as acceleration structures.

Every shape needs a material and a transformation.

## Materials
Materials are defined in a concrete type:
```@docs
Material
```
### Pigments
The emission of the material can be defined as a pigment, which is a subtype of [`AbstractPigment`](). 

They are based on the ColorTypes.jl package, of which we use the `RGB` type.

There are three types of pigments:
```@docs
UniformPigment
CheckeredPigment
ImagePigment
```

### BRDFs
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

## Transformations
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

## Shapes
Shapes are defined as a subtype of [`AbstractShape`](). There are two categories of shapes:, the ones that can be used in CSG operations and the ones that cannot, such as flat shapes.
### Water-tight Shapes
```@docs
Sphere
Box
Cone
Cylinder
```
#### CSG Shapes
Set operations are defined as methods on the [`AbstractSolid`]()` type. The available operations are:
```@docs
CSGUnion
CSGIntersection
CSGDifference
```

### Flat Shapes
```@docs
Plane
Triangle
Parallelogram
Rectangle
Circle
```
### Meshes
Meshes are defined as structs that hold a vector of triangles, a vector of points and the file from which the mesh was loaded.

```@docs
mesh
read_obj_file
jujutracer.trianglize
```


## Acceleration Structures
Acceleration structures are used to speed up the ray tracing process by reducing the number of intersection tests.

The most basic acceleration structure is the [`AABB`](), which is an axis-aligned bounding box that contains a shape. It is used to quickly eliminate shapes that are not intersected by a ray.
```@docs
AABB
```

Otherwise, jujutracer provides the means to build a binary tree of shapes using Boundary Volume Hierarchy (BVH) algorithm. The BVH is a tree structure that allows to quickly find the closest intersection between a ray and a shape.
The BVH is built from a vector of shapes, which wil be divided into nodes with two possible methods:
 - simple: the shapes are divided into two groups based on their centroids
 - surface area heuristic (SAH): the shapes are divided into two groups based on their surface area, which is a more efficient method.
After that, the BVH is held in a [`BVHShape`](), which is a subtype of [`AbstractShape`]().
```@docs
BuildBVH!
jujutracer.Subdivide!
jujutracer.SubdivideSAH!
BVHShape
```

!!! caution "BVHs and large shapes"
    When using BVHs, and in particular when using the SAH method, adding to the accelerated shapes a large shape which cointains other shapes (such as a box or a sphere used as sky) can lead to a large leaf node, when the first split occurs. This can lead to a very slow rendering time, as the ray tracing algorithm will have to check every shape in the leaf node for intersection.

An example of using a BVH is when accelerating a mesh object:
```julia
m_tree = mesh("asset/tree.obj"; order = "whd") # Beware that the mesh holds triangles, and not AbstractShapes.

shapes = Vector{AbstractShape}()
for t in m_tree.shapes
    push!(shapes, t)
end

bvh, bvhdepth = BuildBVH!(shapes; use_sah=true) # Returns the root node of the BVH and its depth.
# `shapes` is rearranged according to the BVH intersection order.
bvhshape = BVHShape(bvh, shapes)
```

## Light Sources
Light sources are defined as a subtype of [`AbstractLight`](). They are used to illuminate the scene.
```@docs
LightSource
SpotLight
```

### World
Once the shapes are defined (and lights), they can be added to the world. A vector of shapes and lights need to be prepared, from which the world will be created.
```@docs
World
```
An example of creating a world is as follows:
```julia
shapes = Vector{AbstractShape}()
lights = Vector{AbstractLight}()

push!(shapes, sphere)
push!(shapes, ground)
push!(lights, light1)
push!(lights, spot1)

world = World(shapes, lights)
```

