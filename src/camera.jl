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

