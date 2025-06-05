module jujutracer

#using
using Images, FileIO, ImageIO
using Base.Threads
using ProgressLogging
using TerminalLoggers
using Logging

# import
import Base:
    +, -, *, ≈, /, sort, sign, (==)
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
export Vec, Point, Normal, squared_norm, norm, normalize, to_string, ⋅, ×, Transformation, Translation, Scaling, Rx, Ry, Rz, ⊙, inverse, _unsafe_inverse, create_onb_from_z 

include("camera.jl")
export Ray, AbstractCamera, Orthogonal, Perspective

include("imagetracer.jl")
export ImageTracer

include("brdf.jl")
export UniformPigment, CheckeredPigment, ImagePigment, AbstractBRDF, DiffusiveBRDF, SpecularBRDF, Material

include("shapes/shapes.jl")

include("renderer.jl")
export OnOff, Flat, PathTracer

include("lexer.jl")
export SourceLocation, InputStream, InputStreamError, open_InputStream, _update_pos!, read_char, unread_char!, skip_whitespaces_and_comments!, AbstractToken, IdentifierToken, StringToken, NumberToken, SymbolToken, KeywordToken, StopToken, read_token, KeywordEnum

include("parser.jl")
export Scene

end # module jujutracer