# Introduction
The jujutracer module allows creating 3D scenes by following a well defined physical model. It is based on a ray tracing algorithm that simulates the interaction of light with objects in a scene.

The intersection of rays with objects is the core of the rendering process. A full geometry framework is provided as the basis for the instersection logic, which handles all the transformation from the local coordinates of the shapes to the world coordinates, and vice versa.

## Shapes
All shapes are defined as objects which hold a material and a transformation. The material defines the appearance of the shape, while the transformation defines its position and orientation in the scene. The following shapes are supported:
- plane
- sphere
- box
- cone
- cylinder
- triangle
- parallelogram
- rectangle
- circle
- mesh (of triangles)

### Costructive Solid Geometry (CSG)
Jujutracer supports Constructive Solid Geometry (CSG) operations, which allow combining shapes using set operations: union, intersection, and difference.
CSG can be applied only to *water-tight* shapes, which are:
- sphere
- box
- cone
- cylinder

## Materials
Materials defines how a ray interacts with a shape. Materials can be emissive, and the interaction modeled by the material's surface is defined by a BRDF (Bidirectional Reflectance Distribution Function). Both emission and BRDF are defined upon pigments, which define the material's texture.
### BRDFs
In jujutracer, there are two brdf types:
- **diffuse**: This type of BRDF models a surface that scatters light uniformly in all directions.
- **specular**: This type of BRDF models a surface that reflects light as a perfect mirror.
### Pigments
In jujutracer, pigments are used both in the emission and in the BRDF. There are three types of pigments:
- **uniform**: This pigment defines a constant color.
- **checkered**: This pigment defines a checkered pattern with two colors.
- **image**: This pigment defines a texture loaded from an image file.

## Transformations
Transformations are used to position and orient shapes in the scene. Jujutracer provides the following transformations (and their combinations):
- **identity**: The identity transformation, which does not change the shape.
- **translation**: Moves a shape by a specified vector.
- **rotation**: Rotates a shape around an axis.
- **scaling**: Scales a shape by a specified factor.

## Camera
The camera is defined by its position, a transformation, a distance to the focal plane, and the aspect ratio. Jujutracer supports two types of cameras:
- **perspective**: This camera represent a perspective projection.
- **orthogonal**: This camera represents an orthoghonal projection.

Rays are fired from the camera's position towards the scene.

## Light sources
As per the physical model, light sources are defined as objects that emit light. That is, every object with an emissive pigment is a light source. However, jujutracer provides point-light sources used in partcular rendering algorithm. These point-light sources are:
- **point light**: A point light source emits light uniformly in all directions from a single point.
- **spot light**: A spot light source emits light as a cone from a single point.

## Renderer
The renderer is responsible for rendering the scene by firing rays from the camera and trace them through every intersection.
Jujutracer provides several rendering algorithms:
- **on off renderer**: This renderer simply checks if a ray intersects with an object and returns the same color for every intersection. It is the simplest rendering algorithm.
- **flat renderer**: This renderer returns the combination of the emissive pigment and the BRDF pigment of the first intersection. 
- **path tracer**: This renderer is based on the path tracing algorithm, which leverages monte carlo integration to sample diffusion and reflection of light in the scene. It is the most advanced rendering algorithm, and it can produce realistic images by accounting for emission and reflection of light in the scene.
- **point light tracer**: This renderer is based on the point light tracing algorithm, which traces rays from the camera to the (point) light sources in the scene. It is a simplified version of the path tracer, it does not account sample light diffusion but approximates it.