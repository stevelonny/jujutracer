#---------------------------------------------------------
# Sphere and methods
#---------------------------------------------------------

"""
    struct Sphere <: AbstractSolid

A sphere.
This structure is a subtype of [`AbstractSolid`](@ref).
# Fields
- `t::Transformation`: the transformation applied to the sphere.
- `Mat::Material`: the material of the shape
"""
struct Sphere <: AbstractSolid
    Tr::AbstractTransformation
    Mat::Material

    function Sphere()
        new(Transformation(), Material())
    end
    function Sphere(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function Sphere(Mat::Material)
        new(Transformation(), Mat)
    end
    function Sphere(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end

"""
    _sphere_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the sphere.
# Arguments
- `p::Point`: the point on the sphere.
- `dir::Vec`: the direction vector of the ray.
# Returns
- `Normal`: the normal to the sphere's surface at the point.
"""
function _sphere_normal(p::Point, dir::Vec)
    norm = Normal(p.x, p.y, p.z)
    return (Vec(p) ⋅ dir < 0.0) ? norm : -norm
end

"""

    _point_to_uv(S::Sphere, p::Point)

Calculate the UV coordinates of a point on the sphere.
# Arguments
- `S::Sphere` the Sphere
- `p::Point` the point on the sphere
# Returns
- `SurfacePoint`: the UV coordinates of the point on the sphere
"""
function _point_to_uv(S::Sphere, p::Point)
    return SurfacePoint(0.5 + atan(p.y, p.x) / (2.0 * π), acos(p.z) / π)
end

"""
    ray_intersection(s::Sphere, r::Ray)

Calculates the intersection of a ray and a sphere.
# Arguments
- `S::Sphere`: the sphere to be intersected
- `ray::Ray`: the ray intersecting the sphere
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(S::Sphere, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    # precompute common values, probably not needed as the compiler is already smart enough
    O_dot_d = O ⋅ d # its sign tells wheter the ray is moving towards or away from ray's origin
    d_squared = squared_norm(d)
    O_squared = squared_norm(O) # position of the ray's origin

    if O_squared > 1.0 && O_dot_d > 0.0
        return nothing
    end

    Δrid = O_dot_d * O_dot_d - d_squared * (O_squared - 1.0)

    Δrid <= 0.0 && return nothing

    sqrot = sqrt(Δrid)
    t1 = (-O_dot_d - sqrot) / d_squared
    t2 = (-O_dot_d + sqrot) / d_squared
    first_hit = if t1 > inv_ray.tmin && t1 < inv_ray.tmax
        t1
    elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax
        t2
    else
        return nothing
    end

    # point in the sphere's local coordinates
    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_P=S.Tr(hit_point),
        normal=S.Tr(_sphere_normal(hit_point, ray.dir)),
        surface_P=_point_to_uv(S, hit_point),
        t=first_hit,
        ray=ray,
        shape=S
    )
end

"""
    ray_intersection_list(S::Sphere, ray::Ray)

Calculates all intersections of a ray with a sphere.
# Arguments
- `S::Sphere`: The sphere to be intersected.
- `ray::Ray`: The ray intersecting the sphere.
# Returns
- `Vector{HitRecord}`: A list of of the two hit records for the two intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(S::Sphere, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    # precompute common values, probably not needed as the compiler is already smart enough
    O_dot_d = O ⋅ d # its sign tells wheter the ray is moving towards or away from ray's origin
    d_squared = squared_norm(d)
    O_squared = squared_norm(O) # position of the ray's origin

    if O_squared > 1.0 && O_dot_d > 0.0
        return nothing
    end

    Δrid = O_dot_d * O_dot_d - d_squared * (O_squared - 1.0)

    Δrid <= 0.0 && return nothing

    sqrot = sqrt(Δrid)
    t1 = (-O_dot_d - sqrot) / d_squared
    t2 = (-O_dot_d + sqrot) / d_squared
    if t1 > inv_ray.tmin && t1 < inv_ray.tmax && t2 > inv_ray.tmin && t2 < inv_ray.tmax
        # actually they are not yet ordered by distance
        first_hit = t1
        second_hit = t2
    else # return nothing if both hits are outside the ray's range
        return nothing
    end

    hit_point_1 = inv_ray(first_hit)
    hit_point_2 = inv_ray(second_hit)
    HR1 = HitRecord(
        world_P=S.Tr(hit_point_1),
        normal=S.Tr(_sphere_normal(hit_point_1, ray.dir)),
        surface_P=_point_to_uv(S, hit_point_1),
        t=first_hit,
        ray=ray,
        shape=S
    )
    HR2 = HitRecord(
        world_P=S.Tr(hit_point_2),
        normal=S.Tr(_sphere_normal(hit_point_2, ray.dir)),
        surface_P=_point_to_uv(S, hit_point_2),
        t=second_hit,
        ray=ray,
        shape=S
    )
    return t1 < t2 ? [HR1, HR2] : [HR2, HR1]
end

"""
    internal(S::Sphere, P::Point)

Checks if a point is inside a sphere.
# Arguments
- `S::Sphere`: The sphere to check.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the sphere, `false` otherwise.
"""
function internal(S::Sphere, P::Point)
    return (squared_norm(Vec(_unsafe_inverse(S.Tr)(P))) <= 1.0) ? true : false
end

"""
    boxed(S::Sphere)::Tuple{Point, Point}

Returns the bounding box of the sphere.
# Arguments
- `S::Sphere`: The sphere for which to calculate the bounding box.
# Returns
- `Tuple{Point, Point}`: A tuple containing the two opposite corners of the bounding box of the sphere.
"""
function boxed(S::Sphere)::Tuple{Point, Point}
    # return P1 and P2 of the bounding box of the sphere
    # remember to apply the transformation to the points
    p1 = Point(-1.0, -1.0, -1.0)
    p2 = Point(1.0, 1.0, 1.0)
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