module jujutracer

# imports
import Base:
    +, -, *, ≈, /
import ColorTypes: ColorTypes, RGB
import Colors: RGB
##

greet() = println("Hello World!")

#export


# includes
include("color.jl")
# include("hdrimg.jl")

end # module jujutracer
