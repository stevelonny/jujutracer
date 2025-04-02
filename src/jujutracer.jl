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
export _lumi_mean, _lumi_weighted, _lumi_D, _lumi_Func, _RGBluminosity

include("hdrimg.jl")
export hdrimg, valid_coordinates, InvalidPfmFileFormat, _read_float, _parse_endianness, _parse_image_size, _read_line, read_pfm_image


end # module jujutracer