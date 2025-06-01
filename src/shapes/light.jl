#---------------------------------------------------------
# Light source
#---------------------------------------------------------

struct LightSource
    position::Point
    emission::UniformPigment
    scale::Float64
    function LightSource(position::Point, emission::UniformPigment, scale::Float64 = 1.0)
        new(position, emission, scale)
    end
end
