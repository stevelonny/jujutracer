#--------------------------------------------------------------------------
# Camera type
#--------------------------------------------------------------------------
"""
    abstract type Camera
Abastact type Camera
"""
abstract type Camera end

"""
    Orthogonal
Orthogonal camera type
"""
struct Orthogonal <: Camera
    t::Transformation = Transformation()
    a_ratio::Float64 = 16//9
end

"""
    Perspective
Perspective camera type
"""
struct Perspective <: Camera
    d::Float64
    t::Transformation = Transformation()
    a_ratio::Float64 = 16//9
end

function (c::Camera)(u::Float64, v::Float64)
    origin = _origin(c,u,v)
    direction = _direction(c,u,v)
    return c.t(Ray(origin,direction,1.0e-5))
end

function _origin(p::Perspective,u::Float64,v::Float64)
    return Point(-p.d,0.0,0.0)
end

function _direction(p::Perspective,u::Float64,v::Float64)
    return Vec(p.d, (1.0 - 2 * u) * p.a_ratio, 2 * v - 1)
end

function _origin(o::ortogonal,u::Float64,v::Float64)
    return Point(-1.0, (1.0 - 2 * u) * o.a_ratio, 2 * v - 1)
end

function _direction(o::ortogonal,u::Float64,v::Float64)
    return Vec(1.,0.,0.)
end