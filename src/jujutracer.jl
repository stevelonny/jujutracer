module jujutracer

# imports
import Base:
    +, -, *, ≈, /
import ColorTypes: ColorTypes, RGB
import Colors
##

#export
export RGB

greet() = println("Hello World!")



# includes
include("color.jl")
# include("hdrimg.jl")

end # module jujutracer
