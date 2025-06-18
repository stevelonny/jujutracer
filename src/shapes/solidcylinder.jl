#---------------------------------------------------------
# Cylinder
#---------------------------------------------------------

"""
    struct Cylinder <: AbstractSolid

A cylinder of unitary radius and height centered in the origin.
This structure is a subtype of [`AbstractSolid`](@ref).
# Fields
- `Tr::Transformation`: the transformation applied to the sphere.
- `Mat::Material`: the material of the shape
# Constructors
- `Cylinder()`: Creates a new cylinder with default transformation and material.
- `Cylinder(Tr::AbstractTransformation)`: Creates a new cylinder with the specified transformation and default material.
- `Cylinder(Mat::Material)`: Creates a new cylinder with the default transformation and the specified material.
- `Cylinder(Tr::AbstractTransformation, Mat::Material)`: Creates a new cylinder with the specified transformation and material.
"""
struct Cylinder <: AbstractSolid
    Tr::AbstractTransformation
    Mat::Material

    function Cylinder()
        new(Transformation(), Material())
    end
    function Cylinder(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function Cylinder(Mat::Material)
        new(Transformation(), Mat)
    end
    function Cylinder(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end

"""
    _cylinder_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the cylinder.
# Arguments
- `p::Point`: the point on the cylinder.
- `dir::Vec`: the direction vector of the ray.
# Returns
- `Normal`: the normal to the cylinder's surface at the point.
"""
function _cylinder_normal(p::Point, dir::Vec)
    # if p.z = ± 0.5 than the normal is vertical, 
    # else if the point lies on the curve surface the normal is radial
    norm = Normal(p.x * (0.25 - p.z^2), p.y * (0.25 - p.z^2), 1.0 * (1.0 - (p.x^2 + p.y^2)))
    return (Vec(p) ⋅ dir < 0.0) ? norm : -norm
end

"""
    _point_to_uv(S::Cylinder, p::Point)

Calculate the UV coordinates of a point on the cylinder.
# Arguments
- `S::Cylinder` the cylinder.
- `p::Point` the point on the cylinder.
# Returns
- `SurfacePoint`: the UV coordinates of the point on the cylinder.
"""
function _point_to_uv(S::Cylinder, p::Point)
    return SurfacePoint(0.5 + atan(p.y, p.x) / (2.0 * π), round(p.z + 0.5; digits=2))
end

"""
    ray_intersection(s::Cylinder, r::Ray)

Calculates the intersection of a ray and a cylinder.
# Arguments
- `S::Cylinder`: the sphere to be intersected
- `ray::Ray`: the ray intersecting the sphere
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(S::Cylinder, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    # precompute common values, probably not needed as the compiler is already smart enough
    O_dot_d = O.x * d.x + O.y * d.y
    d_squared = d.x^2 + d.y^2
    O_squared = O.x^2 + O.y^2

    Δrid = O_dot_d * O_dot_d - d_squared * (O_squared - 1.0)

    (Δrid <= 0.0 && d_squared != 0.0) && return nothing

    t1z = (0.5 - O.z) / d.z
    t2z = (-0.5 - O.z) / d.z
    if d_squared != 0.0
        sqrot = sqrt(Δrid)
        t1 = (-O_dot_d - sqrot) / d_squared
        t2 = (-O_dot_d + sqrot) / d_squared
    else
        t1 = t1z
        t2 = t2z
    end

    # more concise version but i dont really trust it
    tmin = max(min(t1, t2), min(t1z, t2z))
    tmax = min(max(t1, t2), max(t1z, t2z))

    if tmax < max(inv_ray.tmin, tmin)
        return nothing
    end
    first_hit = tmin > inv_ray.tmin ? tmin : tmax
    first_hit > inv_ray.tmax && return nothing

    # point in the cylinder's local coordinates
    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_P=S.Tr(hit_point),
        normal=S.Tr(_cylinder_normal(hit_point, d)),
        surface_P=_point_to_uv(S, hit_point),
        t=first_hit,
        ray=ray,
        shape=S
    )
end

"""
    ray_intersection_list(S::Cylinder, ray::Ray)

Calculates all intersections of a ray with a cylinder.
# Arguments
- `S::Cylinder`: The sphere to be intersected.
- `ray::Ray`: The ray intersecting the sphere.
# Returns
- `Vector{HitRecord}`: A list of of the two hit records for the two intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(S::Cylinder, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir

    O_dot_d = O.x * d.x + O.y * d.y
    d_squared = d.x^2 + d.y^2
    O_squared = O.x^2 + O.y^2

    Δrid = (O_dot_d)^2 - d_squared * (O_squared - 1)

    (Δrid <= 0.0 && d_squared != 0.0) && return nothing

    t1z = (0.5 - O.z) / d.z
    t2z = (-0.5 - O.z) / d.z
    if d_squared != 0.0
        sqrot = sqrt(Δrid)
        t1 = (-O_dot_d - sqrot) / d_squared
        t2 = (-O_dot_d + sqrot) / d_squared
    else
        t1 = t1z
        t2 = t2z
    end

    # more concise version but i dont really trust it
    tmin = max(min(t1, t2), min(t1z, t2z))
    tmax = min(max(t1, t2), max(t1z, t2z))

    if tmax < max(inv_ray.tmin, tmin) || tmax > inv_ray.tmax
        return nothing
    end
    if tmin < inv_ray.tmin || tmin > inv_ray.tmax
        return nothing
    end

    first_hit = tmin
    second_hit = tmax

    # when a ray is originated inside the cylinder, the equation gives also the solution of the intersection in the opposite direction
    if signbit(first_hit - ray.tmin)
        first_hit = Inf
        second_hit = Inf
    elseif signbit(second_hit - ray.tmin)
        second_hit = Inf
    end

    if first_hit == Inf && second_hit == Inf
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
    return [HR1, HR2]
end

"""
    internal(S::Cylinder, P::Point)

Checks if a point is inside a cylinder.
# Arguments
- `S::Cylinder`: The cylinder to check.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the cylinder, `false` otherwise.
"""
function internal(S::Cylinder, P::Point)
    p = _unsafe_inverse(S.Tr)(P)
    circle = (p.x^2 + p.y^2 <= 1.0)
    z = (p.z^2 <= 0.25)
    return (circle && z) ? true : false
end

"""
    boxed(S::Cylinder)::Tuple{Point, Point}

Returns the bounding box of the cylinder.
# Arguments
- `S::Cylinder`: The cylinder for which to calculate the bounding box.
# Returns
- `Tuple{Point, Point}`: A tuple containing the two opposite corners of the bounding box of the cylinder.
"""
function boxed(S::Cylinder)::Tuple{Point,Point}
    # return P1 and P2 of the bounding box of the sphere
    # remember to apply the transformation to the points
    p1 = Point(-1.0, -1.0, -0.5)
    p2 = Point(1.0, 1.0, 0.5)
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
    quick_ray_intersection(S::Cylinder, ray::Ray)::Bool
Checks if a ray intersects with the cylinder without calculating the exact intersection point.
# Arguments
- `S::Cylinder`: The cylinder to check for intersection.
- `ray::Ray`: The ray to check for intersection with the cylinder.
# Returns
- `Bool`: `true` if the ray intersects with the cylinder, `false` otherwise.
"""
function quick_ray_intersection(S::Cylinder, ray::Ray)::Bool
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir

    O_dot_d = O.x * d.x + O.y * d.y
    d_squared = d.x^2 + d.y^2
    O_squared = O.x^2 + O.y^2

    Δrid = (O_dot_d)^2 - d_squared * (O_squared - 1.0)

    (Δrid <= 0.0 && d_squared != 0.0) && return false

    t1z = (0.5 - O.z) / d.z
    t2z = (-0.5 - O.z) / d.z
    if d_squared != 0.0
        sqrot = sqrt(Δrid)
        t1 = (-O_dot_d - sqrot) / d_squared
        t2 = (-O_dot_d + sqrot) / d_squared
    else
        t1 = t1z
        t2 = t2z
    end

    # more concise version but i dont really trust it
    tmin = max(min(t1, t2), min(t1z, t2z))
    tmax = min(max(t1, t2), max(t1z, t2z))

    return !(tmax < max(inv_ray.tmin, tmin) || tmax > inv_ray.tmax || (tmin < inv_ray.tmin || tmin > inv_ray.tmax))
end