#---------------------------------------------------------
# Light source
#---------------------------------------------------------

"""
    struct LightSource
A struct representing a light source in a 3D scene.
# Fields
- `position::Point`: the position of the light source in 3D space.
- `emission::RGB`: the color of the light emitted by the source.
- `scale::Float64`: the scale factor for the light source, affecting its intensity.
# Constructors
- `LightSource(position::Point, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=1.0)`: Creates a new light source with the specified position, emission color, and scale factor.
"""
struct LightSource
    position::Point
    emission::RGB
    scale::Float64
    function LightSource(position::Point, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=1.0)
        new(position, emission, scale)
    end
end
