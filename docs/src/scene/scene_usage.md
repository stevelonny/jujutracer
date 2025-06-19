# Scene Usage
The main feature of this project is developed in `interpreter.jl` <!--[`interpreter.jl`](https://github.com/stevelonny/jujutracer/blob/main/interpreter.jl)--> which, from a `scene.txt` file, is able to parse the construction of the desired scene. The rendering of the scene is not completly yield from the scene file:  the type of renderer, the image resolution, the antialiasing and other parameters are specified at the time of execution.

Follows some instruction for writing a correct `scene.txt`.

## Float variables
Float variables are used to define some constants that can be used in the scene.

They are defined by calling the keyword `float` followed by the name of the variable and the value between parenthesis.
```text
float name({value})
```
For example, to define the value of pi:
```text
float pi(3.141592653589793)
```

## Materials
Materials are defined by the keyword `material` followed by the name of the material, and enclosed in parenthesis the definition of the BRDF and the emission pigment.

**Pigments** are used to define a texture. The most basic types of pigments are `uniform` and `checkered`. They are based on colors, which are defined as follow a triplet of floats:
```text
< r, g, b >
```
Where `r`, `g` and `b` are the red, green and blue components of the color, respectively.
Previously defined float variables can be used to define the color, for example:
```text
< pi, 0.5, 0.2 >
```

A uniform pigment is defined with the keyword `uniform` followed by the color:
```
uniform({color})
```
While a checkered pigment is defined with the keyword `checkered` followed by two colors and the number of subdivisions:
```text
checkered({color1}, {color2}, {n_subdivisions})
```
And finally there is the `image` pigment, which is used to load an image from a file. It is defined with the keyword `image` followed by the path to the image file:
```text
image("path/to/image.pfm")
```

**BRDF** are used to define the interaction of the light with the material.
The most basic type of BRDF is `diffuse`, which is defined with the keyword `diffuse` followed by a pigment:
```text
diffuse({pigment})
```
And there is also the `specular` BRDF, which is defined with the keyword `specular` followed by a pigment:
```text
specular({pigment})
```

Materials are to be declared as variables, which will be used in the definition of the shapes. The syntax is done with the keyword `material` followed by the name of the material, and enclosed in parenthesis the definition of the BRDF and the emission pigment:
```text
material mat_name(
    {brdf},
    {emission_pigment}
)
```

Some examples of materials:
```text
material ground_material(
    diffuse(checkered(<0.3, 0.5, 0.1>,
                      <0.1, 0.2, 0.5>, 4)),
    uniform(<0, 0, 0>)
)

material sphere_material(
    specular(uniform(<0.5, 0.5, 0.5>)),
    uniform(<0, 0, 0>)
)

material sky_material(
    diffuse(image("asset/sky.pfm")),
    uniform(<0, 0, 0>)
)
```

## Transformations
Transformations are used both in shapes definitions and to orient the camera. 
The supported transformations are defined with the keywords `identity`, `translation`, `rotation_x`, `rotation_y`, `rotation_z` and `scaling`. They are defined as follows:
```text
identity
translation([x, y, z])
rotation_x(angle)
rotation_y(angle)
rotation_z(angle)
scaling([x, y, z])
```
Where `angle` is in radians and `[x, y, z]` are the components of the vector.
Previously defined float variables can be used to define the angle or the vector values.

They can be combined together by using the `*` operator, which is the composition of the transformations. For example, to rotate an object around the x-axis and then translate it:
```text
float angle(30.0)

...

rotation_x(angle) * translation([1, 0, 0])
```
## Shapes
Shapes are defined similar to materials. They are define by applying the keyword corresponding to the type of shape, followed by the name of the shape and enclosed in parenthesis the material and the transformation, or in some cases the parameters of the shape.
```text
sphere({material_name}, {transformation})
box({material_name}, {transformation})
cylinder({material_name}, {transformation})
cone({material_name}, {transformation})
plane({material_name}, {transformation})
circle({material_name}, {transformation})
rectangle({material_name}, {transformation})
```

Other shapes are to be defined with additional parameters.
```text
triangle({material_name}, {v1}, {v2}, {v3})
parallelogram({material_name}, {v1}, {v2}, {v3})
```
Where `{v1}`, `{v2}` and `{v3}` are the vertices of the triangle or parallelogram, defined as the vector `[x, y, z]`.

Some examples of shapes:
```text
sphere sphere1(
    sphere_material,
    translation([0, 0, 0]) * scaling([0.5, 0.5, 0.5])
)

box box1(
    ground_material,
    translation([0, -0.5, 0]) * scaling([2, 0.5, 2])
)

triangle triangle1(
    sphere_material,
    [0, 0, 0],
    [1, 0, 0],
    [0, 1, 0]
)
```

## CSG Shapes
CSG (Constructive Solid Geometry) shapes are defined by combining other shapes using boolean operations. As per shapes, they are defined by applying the keyword corresponding to the type of CSG shape, followed by the name of the shape and enclosed in parenthesis transformation, first shape and second shape. The shapes used must be *water-tight*.

The supported CSG shapes are `union`, `intersection` and `difference`:
```text
union name({transformation}, {shape1}, {shape2})`
difference name({transformation}, {shape1}, {shape2})`
intersection name({transformation}, {shape1}, {shape2})`
```
Where `{shape1}` and `{shape2}` are the names of the shapes to be combined, and can be other CSG shapes. Shapes need to be defined before the CSG shapes.

Some examples of CSG shapes:
```text
union union1(
    translation([0, 0, 0]) * scaling([0.5, 0.5, 0.5]),
    sphere1,
    box1
)
difference difference1(
    translation([0, 0, 0]) * scaling([0.5, 0.5, 0.5]),
    sphere1,
    box1
)
intersection intersection1(
    translation([0, 0, 0]) * scaling([0.5, 0.5, 0.5]),
    sphere1,
    box1
)

union union2(
    translation([0, 0, 0]) * scaling([0.5, 0.5, 0.5]),
    union1,
    difference1
)
```

## Meshes
External models in the OBJ format can be loaded as meshes. They are defined with the keyword `mesh` followed by the name of the mesh, and in parenthesis the name of the material to be used, the transformation to be applied to the mesh, the filename of the mesh and the expected order for the coordinates.
```text
mesh({material_name}, {transformation}, {filename}, {order})
```
Where `{filename}` is a string defined as `"path/to/mesh.obj"`. The last parameter `{order}` is a string that defines the order of the coordinates in the OBJ file, which define the coordinates of the vertices. The expected format is a succesion of `d`, `w` and `h`, where `d` stands for depth, `w` for width and `h` for height. For example, if the OBJ file has the coordinates in the order `[x, y, z]`, the order is `"dwh"`. If the coordinates are in the order `[x, z, y]`, the order is `"whd"`

Some examples of meshes:
```text
mesh tree(mat_tree, translation([-5.0, 0.0, -0.05]) * scaling([tree_scale, tree_scale, tree_scale]), "asset/tree.obj", "whd")
mesh m1(mat_box, translation([1.5, 2.5, 0.0]) * scaling([0.1, 0.1, 0.1]) * translation([0.0, 0.0, -3.05]), "humanoid_tri.obj", "dwh")
```

## Lights
Point-like lights are used in the Point Light Tracing renderer.

Point lights are defined with the keyword `pointlight` followed by the name of the light, the position of the light and the color of the light. The position is defined as a vector `[x, y, z]` and the color as a triplet of floats `<r, g, b>`.
```text
pointlight name([x, y, z], {color}, {scale_factor})
```

Spotlights are defined with the keyword `spotlight` followed by the name of the light, the position of the light, the direction of the light, the color of the light, the angle of the cone of light, the falloff angle, and finally the scale factor.
```text
spotlight name([x, y, z], [dx, dy, dz], {color}, {angle}, {falloff_angle}, {scale_factor})
```
Where `[dx, dy, dz]` is the direction of the light.


## World and camera
Once the shapes have been defined, they need to be added to the world. Shapes are added with the keyword `add` followed by the name of the shape.
```text
add sphere1
add box1
add union2
```

Also lights need to be added to the world, with the same keyword `add` followed by the name of the light:
```text
add pointlight1
add spotlight1
```

!!! note "CSG and Meshes"
    Under the hood, some shapes are automatically boxed into [acceleration structures](#acceleration-structures):
    - CSG shapes are boxed into an AABB.
    - mesh constituents are boxed into the **same** BVH.

And last, but not the least, a camera needs to be defined. The camera is defined with the keyword `camera` followed by the type of camera, the transformation to be applied to the camera, and the aspect ratio. The type of camera can be either `perspective` or `orthogonal`. The perspective camera also requires a screen distance.
```text
# perspective
camera(perspective, {tranformation}, {aspect_ratio}, {screen_distance})
# orthogonal
camera(orthogonal, {tranformation}, {aspect_ratio})
```
`{aspect_ratio}` and `{screen_distance}` are both float variables.

