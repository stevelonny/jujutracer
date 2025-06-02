#---------------------------------------------------------
# Light source
#---------------------------------------------------------

abstract type AbstractLight end

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
struct LightSource <: AbstractLight
    position::Point
    emission::RGB
    scale::Float64
    function LightSource(position::Point, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=100.0)
        new(position, emission, scale)
    end
end

struct SpotLight <: AbstractLight
    position::Point
    direction::Vec
    emission::RGB
    scale::Float64
    cos_total::Float64
    cos_falloff::Float64
    cos_start::Float64

    function SpotLight(position::Point, direction::Vec, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=100.0, cos_total::Float64=0.9, cos_falloff::Float64=0.93, cos_start::Float64=0.95)
        new(position, direction, emission, scale, cos_total, cos_falloff, cos_start)     
    end
end
