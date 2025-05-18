module jujutracer

#using
using Images, FileIO, ImageIO

# import
import Base:
    +, -, *, ≈, /, sort
import ColorTypes: ColorTypes, RGB
import Colors

#export
export RGB

greet() = println("Hello World!")

# includes
include("color.jl")

include("hdrimg.jl")
export hdrimg, valid_coordinates, average_luminosity, tone_mapping

include("inputoutput.jl")
export save_ldrimage, get_matrix, write_pfm_image, InvalidPfmFileFormat, read_pfm_image

include("geometry.jl")
export Vec, Point, Normal, squared_norm, norm, normalize, to_string, ⋅, ×, Transformation, Translation, Scaling, Rx, Ry, Rz, ⊙, inverse

include("camera.jl")
export Ray, AbstractCamera, Orthogonal, Perspective

include("imagetracer.jl")
export ImageTracer

include("brdf.jl")
export UniformPigment, CheckeredPigment, ImagePigment, DiffusiveBRDF, Material

include("shapes.jl")
export SurfacePoint, HitRecord, AbstractShape, AbstractSolid, Sphere, ray_intersection, Plane, Rectangle, World, Eval

include("meshes.jl")
export Mat, Sarrus, Triangle, ray_intersection, Quadrilateral

include("csg.jl")
export CSGUnion, CSGDifference, CSGIntersection, ray_intersection, internal

include("renderer.jl")
export OnOff, Flat
end # module jujutracer