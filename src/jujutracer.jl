module jujutracer

#using
using Images, FileIO, ImageIO
using Base.Threads

# import
import Base:
    +, -, *, ≈, /, sort, sign
import ColorTypes: ColorTypes, RGB
import Colors

#export
export RGB

greet() = println("Hello World!")

# includes
include("color.jl")

include("randgen.jl")
export PCG, rand_pcg, rand_uniform, rand_unif_hemisphere

include("hdrimg.jl")
export hdrimg, valid_coordinates, average_luminosity, tone_mapping

include("inputoutput.jl")
export save_ldrimage, get_matrix, write_pfm_image, InvalidPfmFileFormat, read_pfm_image

include("geometry.jl")
export Vec, Point, Normal, squared_norm, norm, normalize, to_string, ⋅, ×, Transformation, Translation, Scaling, Rx, Ry, Rz, ⊙, inverse, create_onb_from_z 

include("camera.jl")
export Ray, AbstractCamera, Orthogonal, Perspective

include("imagetracer.jl")
export ImageTracer

include("brdf.jl")
export UniformPigment, CheckeredPigment, ImagePigment, AbstractBRDF, DiffusiveBRDF, SpecularBRDF, Material

include("shapes.jl")
export SurfacePoint, HitRecord, AbstractShape, AbstractSolid, Sphere, Box, Cylinder, ray_intersection, ray_intersection_list, Plane, Rectangle, World, Eval

include("meshes.jl")
export Triangle, ray_intersection, ray_intersection_list, Parallelogram

include("csg.jl")
export CSGUnion, CSGDifference, CSGIntersection, ray_intersection, ray_intersection_list, internal

include("renderer.jl")
export OnOff, Flat, PathTracer
end # module jujutracer