#----------------------------------------------------
#Ray 
#----------------------------------------------------
"""
    Ray(origin::Point, dir::Vec, tmin::Float=1e-5, tmax::Float=Inf, depth::Int=0)

A struct representing a ray in 3D space.
# Fields
- `origin::Point`: The origin point of the ray.
- `dir::Vec`: The direction vector of the ray.
- `tmin::Float`: The minimum distance along the ray (default is `le-5`).
- `tmax::Float`: The maximum distance along the ray (default is `Inf`).
- `depth::Int`: The depth of the ray (default is `0`).
"""
struct Ray
    origin::Point
    dir::Vec 
    tmin::Float64 
    tmax::Float64
    depth::Int
    #Should vec be normalised?

    function Ray(;origin::Point, dir::Vec, tmin=1e-5, tmax=Inf, depth=0)
        new(origin, dir, tmin, tmax, depth)
    end

end

Base.:≈(r1::Ray, r2::Ray) = r1.origin ≈ r2.origin && r1.dir ≈ r2.dir

"""
    (r::Ray)(t::Float64)

Return the point along the ray at distance `t` from the origin.
"""
function (r::Ray)(t::Float64)
    if t < r.tmin || t > r.tmax
        throw(ArgumentError("t must be in the range [$(r.tmin), $(r.tmax)]"))
    else
        return r.origin + t * r.dir
    end
end

function (Tr::AbstractTransformation)(ray::Ray)
    return Ray(origin = Tr(ray.origin), 
    dir = Tr(ray.dir), 
    tmin = ray.tmin, 
    tmax = ray.tmax, 
    depth = ray.depth)
end

#--------------------------------------------------------------------------
# Camera type
#--------------------------------------------------------------------------
"""
    abstract type AbstractCamera
Abstact type AbstractCamera

`AbstractCamera(u, v)` returns a ray fired in the pixel (u, v) of the screen
"""
abstract type AbstractCamera end

"""
    Orthogonal
Orthogonal camera type

# Fields 
- `t::Transformation` the transformation related to the camera's standing
- `a_ratio::Float64` aspect ratio of the screen of the camera
# Constructor 
- `Orthogonal()` creates an orthogonal camera with Identity `Transformation` and a 16:9 aspect ratio
- `Ortoghonal(t = trans, a_ratio = a)` creates an orthogonal camera with trans `Transformation` and an `a` aspect ratio
"""
struct Orthogonal <: AbstractCamera
    t::Transformation
    a_ratio::Float64 
    function Orthogonal(;t::Transformation = Transformation(), a_ratio::Float64 = 16//9)
        new(t, a_ratio)
    end
end

"""
    Perspective
Perspective camera type

# Fields 
- `t::Transformation` the transformation related to the camera's standing
- `a_ratio::Float64` aspect ratio of the screen of the camera
# Constructor 
- `Perspective()` creates a perspective camera with Identity `Transformation`, a 16:9 aspect ratio placed in (-1, 0, 0)
- `Perspective(d = dist, t = trans, a_ratio = a)` creates a perspective camera with trans `Transformation`, an `a` aspect ratio placed in (-d, 0, 0)
"""
struct Perspective <: AbstractCamera
    d::Float64
    t::Transformation 
    a_ratio::Float64 
    function Perspective(;d::Float64 = 1., t::Transformation = Transformation(), a_ratio::Float64 = 16//9)
        new(d, t, a_ratio)
    end
end

function (c::AbstractCamera)(u::Float64, v::Float64)
    return Ray(origin = c.t(_origin(c,u,v)),dir = c.t(_direction(c,u,v)), tmin = 1.0e-5)
end

function _origin(p::Perspective,u::Float64,v::Float64)
    return Point(-p.d,0.0,0.0)
end

function _direction(p::Perspective,u::Float64,v::Float64)
    return Vec(p.d, (1.0 - 2 * u) * p.a_ratio, 2 * v - 1)
end

function _origin(o::Orthogonal,u::Float64,v::Float64)
    return Point(-1.0, (1.0 - 2 * u) * o.a_ratio, 2 * v - 1)
end

function _direction(o::Orthogonal,u::Float64,v::Float64)
    return Vec(1.,0.,0.)
end