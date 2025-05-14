module jujutracer

#using
using Images, FileIO, ImageIO

# import
import Base:
    +, -, *, ≈, /
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

include("shapes.jl")
export SurfacePoint, HitRecord, AbstractShape, Sphere, ray_intersection, Plane, World

include("randgen.jl")
export PCG, rand_pcg, rand_uniform, rand_unif_hemisphere


end # module jujutracer