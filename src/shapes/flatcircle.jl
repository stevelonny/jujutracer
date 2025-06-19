
#---------------------------------------------------------
# Circle
#---------------------------------------------------------

"""
    struct Circle <: AbstractShape

A unit circle in the xy-plane, centered at the origin.
# Fields
- `Tr::AbstractTransformation`: the transformation applied to the circle.
- `Mat::Material`: the material of the shape.
# Constructors
- `Circle()`: Creates a new circle with default transformation and material.
- `Circle(Tr::AbstractTransformation)`: Creates a new circle with the specified transformation and default material.
- `Circle(Mat::Material)`: Creates a new circle with the default transformation and the specified material.
- `Circle(Tr::AbstractTransformation, Mat::Material)`: Creates a new circle with the specified transformation and material.
"""
struct Circle <: AbstractShape
    Tr::AbstractTransformation
    Mat::Material

    function Circle()
        new(Transformation(), Material())
    end
    function Circle(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function Circle(Mat::Material)
        new(Transformation(), Mat)
    end
    function Circle(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end

"""
    _circle_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the circle.
# Arguments
- `p::Point`: the point on the circle.
- `dir::Vec`: the direction vector of the ray.
# Returns
- `Normal`: the normal to the circle's surface at the point.
# Throws
- `ArgumentError`: if the point is outside the circle.
"""
function _circle_normal(p::Point, dir::Vec)
    norm = Normal(0.0, 0.0, 1.0)
    return (dir.z < 0.0) ? norm : -norm
end

"""
    _point_to_uv(S::Circle, p::Point)

Calculate the UV coordinates of a point on the circle.
# Arguments
- `S::Circle`: the circle.
- `p::Point`: the point on the circle.
# Returns
- `SurfacePoint`: the UV coordinates of the point on the circle.
"""
function _point_to_uv(S::Circle, p::Point)
    return _circle_point_to_uv(p)
end

"""
    _circle_point_to_uv(p::Point)
Helper function to convert a point on the circle to UV coordinates.
# Arguments
- `p::Point`: the point on the circle.
# Returns
- `SurfacePoint`: the UV coordinates of the point on the circle.
"""
function _circle_point_to_uv(p::Point)
    r = sqrt(p.x^2 + p.y^2)
    θ = atan(p.y, p.x)
    u = θ / (2.0 * π) + 0.5
    v = r
    return SurfacePoint(u, v)
end

"""
    ray_intersection(S::Circle, ray::Ray)

Calculate the intersection of a ray and a circle.
# Arguments
- `S::Circle`: the circle to be intersected.
- `ray::Ray`: the ray intersecting the circle.
# Returns
- `HitRecord`: The hit record of the intersection, if any.
- `nothing`: If no intersection occurs.
"""
function ray_intersection(S::Circle, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir

    t = -O.z / d.z
    if t > inv_ray.tmin && t < inv_ray.tmax && (inv_ray(t).x^2 + inv_ray(t).y^2) <= 1.0
        first_hit = t
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = S.Tr(_circle_normal(hit_point, d))
    return HitRecord(
        world_P=S.Tr(hit_point),
        normal=norm,
        surface_P=_point_to_uv(S, hit_point),
        t=first_hit,
        ray=ray,
        shape=S
    )
end

"""
    boxed(S::Circle)::Tuple{Point, Point}

Returns the bounding box of the circle.
# Arguments
- `S::Circle`: The circle for which to calculate the bounding box.
# Returns
- `Tuple{Point, Point}`: A tuple containing the two opposite corners of the bounding box of the circle.
"""
function boxed(S::Circle)::Tuple{Point,Point}
    # return P1 and P2 of the bounding box of the circle
    # remember to apply the transformation to the points
    p1 = Point(-1.0, -1.0, 0.0)
    p2 = Point(1.0, 1.0, 0.0)
    corners = [
        Point(x, y, z)
        for x in (p1.x, p2.x),
            y in (p1.y, p2.y),
            z in (p1.z, p2.z)
    ]
    # Transform all corners
    world_corners = [S.Tr(c) for c in corners]
    # Find min/max for each coordinate
    xs = [c.x for c in world_corners]
    ys = [c.y for c in world_corners]
    zs = [c.z for c in world_corners]
    Pmin = Point(minimum(xs), minimum(ys), minimum(zs))
    Pmax = Point(maximum(xs), maximum(ys), maximum(zs))
    return (Pmin, Pmax)
end

"""
    quick_ray_intersection(S::Circle, ray::Ray)::Bool
Checks if a ray intersects with the circle without calculating the exact intersection point.
# Arguments
- `S::Circle`: The circle to check for intersection.
- `ray::Ray`: The ray to check for intersection with the circle.
# Returns
- `Bool`: `true` if the ray intersects with the circle, `false` otherwise.
"""
function quick_ray_intersection(S::Circle, ray::Ray)::Bool
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir

    t = -O.z / d.z
    if t <= inv_ray.tmin || t >= inv_ray.tmax || (inv_ray(t).x^2 + inv_ray(t).y^2) > 1.0
        return false
    else
        return true
    end
end