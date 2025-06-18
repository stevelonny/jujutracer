#---------------------------------------------------------
# Cone
#---------------------------------------------------------

"""
    struct Cone <: AbstractSolid

A cone of unitary radiuos and height resting on the xy plane.
This structure is a subtype of [`AbstractSolid`](@ref).
# Fields
- `Tr::Transformation`: the transformation applied to the sphere.
- `Mat::Material`: the material of the shape
"""
struct Cone <: AbstractSolid
    Tr::AbstractTransformation
    Mat::Material

    function Cone()
        new(Transformation(), Material())
    end
    function Cone(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function Cone(Mat::Material)
        new(Transformation(), Mat)
    end
    function Cone(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end

"""
    _cone_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the cone.
# Arguments
- `p::Point`: the point on the cone.
- `dir::Vec`: the direction vector of the ray.
# Returns
- `Normal`: the normal to the cone's surface at the point.
"""
function _cone_normal(p::Point, dir::Vec)
    if p.z > 0.0
        norm = Normal(p.x, p.y, 1.0 - p.z)
    else
        norm = Normal(0.0, 0.0, -1.0)
    end
    return (Vec(p) ⋅ dir < 0.0) ? norm : -norm
end

"""

    _point_to_uv(S::Cone, p::Point)

Calculate the UV coordinates of a point on the cone.
# Arguments
- `S::Cone` the cone.
- `p::Point` the point on the cone.
# Returns
- `SurfacePoint`: the UV coordinates of the point on the cone.
"""
function _point_to_uv(S::Cone, p::Point)
    return SurfacePoint(0.5 + atan(p.y, p.x) / (2.0 * π), p.z - floor(p.z))
end

"""
    ray_intersection(s::Cone, r::Ray)

Calculates the intersection of a ray and a cone.
# Arguments
- `S::Cone`: the cone to be intersected
- `ray::Ray`: the ray intersecting the cone
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(S::Cone, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    # z = 1 - sqrt(x^2 + y^2)
    # (z - 1)^2 = x^2 + y^2
    a = d.x^2 + d.y^2 - d.z^2
    b = 2.0 * (-O.z * d.z + O.x * d.x + O.y * d.y + d.z)
    c = -1.0 + O.x^2 + O.y^2 - O.z^2 + 2.0 * O.z

    Δ = b^2 - 4.0*a*c
    Δ <= 0.0 && return nothing

    sqrot = sqrt(Δ)
    t1 = (-b - sqrot) / (2.0*a)
    t2 = (-b + sqrot) / (2.0*a)
    z1 = O.z + t1 * d.z
    z2 = O.z + t2 * d.z
    tz = -O.z / d.z
    if t1 > inv_ray.tmin && t1 < inv_ray.tmax && z1 > 0.0 && z1 < 1.0
        first_hit = t1
        if tz < t1 && tz > inv_ray.tmin && tz < inv_ray.tmax
            # if the base is hit before the first intersection, we return the base hit
            hit_base = inv_ray(tz)
            if hit_base.x^2 + hit_base.y^2 <= 1.0
                return HitRecord(
                world_P = S.Tr(hit_base),
                normal = S.Tr(_circle_normal(hit_base, d)),
                surface_P = _circle_point_to_uv(hit_base),
                t = tz,
                ray = ray,
                shape = S
            )
            end
        end
    elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax && z2 > 0.0 && z2 < 1.0
        first_hit = t2
        if tz < t1 && tz > inv_ray.tmin && tz < inv_ray.tmax
            # if the base is hit before the first intersection, we return the base hit
            hit_base = inv_ray(tz)
            if hit_base.x^2 + hit_base.y^2 <= 1.0
                return HitRecord(
                world_P = S.Tr(hit_base),
                normal = S.Tr(_circle_normal(hit_base, d)),
                surface_P = _circle_point_to_uv(hit_base),
                t = tz,
                ray = ray,
                shape = S
            )
            end
        end
    elseif tz > inv_ray.tmin && tz < inv_ray.tmax
        # if the base is hit before the first intersection, we return the base hit
        hit_base = inv_ray(tz)
        if hit_base.x^2 + hit_base.y^2 > 1.0
            return nothing  # base hit is outside the circle
        end
        return HitRecord(
            world_P = S.Tr(hit_base),
            normal = S.Tr(_circle_normal(hit_base, d)),
            surface_P = _circle_point_to_uv(hit_base),
            t = tz,
            ray = ray,
            shape = S
        )
    else
        return nothing
    end
    
    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_P = S.Tr(hit_point),
        normal = S.Tr(_cone_normal(hit_point, d)),
        surface_P = _point_to_uv(S, hit_point),
        t = first_hit,
        ray = ray,
        shape = S
    )
end

"""
    ray_intersection_list(S::Cone, ray::Ray)

Calculates all intersections of a ray with a cone.
# Arguments
- `S::Cone`: The cone to be intersected.
- `ray::Ray`: The ray intersecting the cone.
# Returns
- `Vector{HitRecord}`: A list of of the two hit records for the two intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(S::Cone, ray::Ray)
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    a = d.x^2 + d.y^2 - d.z^2
    b = 2.0 * (-O.z * d.z + O.x * d.x + O.y * d.y + d.z)
    c = -1.0 + O.x^2 + O.y^2 - O.z^2 + 2.0 * O.z

    Δ = b^2 - 4.0*a*c
    Δ <= 0.0 && return nothing
    
    hit_records = HitRecord[]
    
    sqrot = sqrt(Δ)
    t1 = (-b - sqrot) / (2.0*a)
    t2 = (-b + sqrot) / (2.0*a)
    z1 = O.z + t1 * d.z
    z2 = O.z + t2 * d.z
    tz = -O.z / d.z
    if tz > inv_ray.tmin && tz < inv_ray.tmax
        hit_base = inv_ray(tz)
        if hit_base.x^2 + hit_base.y^2 <= 1.0
        HR_base = HitRecord(
            world_P = S.Tr(hit_base),
            normal = S.Tr(_circle_normal(hit_base, d)),
            surface_P = _circle_point_to_uv(hit_base),
            t = tz,
            ray = ray,
            shape = S
        )
        push!(hit_records, HR_base)
        end
    end
    if t1 > inv_ray.tmin && t1 < inv_ray.tmax && z1 > 0.0 && z1 < 1.0
        HR1 = HitRecord(
            world_P = S.Tr(inv_ray(t1)),
            normal = S.Tr(_cone_normal(inv_ray(t1), d)),
            surface_P = _point_to_uv(S, inv_ray(t1)),
            t = t1,
            ray = ray,
            shape = S
        )
        push!(hit_records, HR1)
    end
    if t2 > inv_ray.tmin && t2 < inv_ray.tmax && z2 > 0.0 && z2 < 1.0
        HR2 = HitRecord(
            world_P = S.Tr(inv_ray(t2)),
            normal = S.Tr(_cone_normal(inv_ray(t2), d)),
            surface_P = _point_to_uv(S, inv_ray(t2)),
            t = t2,
            ray = ray,
            shape = S
        )
        push!(hit_records, HR2)
    end
    if length(hit_records) != 2
        return nothing  # no hits found
    end
    sort!(hit_records, by = h -> h.t)  # sort by distance
    return [hit_records[1], hit_records[2]]  # return the first two hits (maybe overkill as it never will be 3 hits), if they exists
end

"""
    internal(S::Cone, P::Point)

Checks if a point is inside a cone.
# Arguments
- `S::Cone`: The cone to check.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the cone, `false` otherwise.
"""
function internal(S::Cone, P::Point)
    p = inverse(S.Tr)(P)
    if p.z < 0.0 || p.z > 1.0
        return false
    end
    return (p.x^2 + p.y^2 < (1.0 - p.z)^2) ? true : false
end

"""
    boxed(S::Cone)::Tuple{Point, Point}

Returns the bounding box of the cone.
# Arguments
- `S::Cone`: The cone to get the bounding box of.
# Returns
- `Tuple{Point, Point}`: A tuple containing the two corners of the bounding box.
"""
function boxed(S::Cone)::Tuple{Point, Point}
    # return P1 and P2 of the bounding box of the sphere
    # remember to apply the transformation to the points
    p1 = Point(-1.0, -1.0, 0.0)
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

"""
    quick_ray_intersection(S::Cone, ray::Ray)::Bool
Checks if a ray intersects with the cone without calculating the exact intersection point.
# Arguments
- `S::Cone`: The cone to check for intersection.
- `ray::Ray`: The ray to check for intersection with the cone.
# Returns
- `Bool`: `true` if the ray intersects with the cone, `false` otherwise.
"""
function quick_ray_intersection(S::Cone, ray::Ray)::Bool
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    a = d.x^2 + d.y^2 - d.z^2
    b = 2.0 * (-O.z * d.z + O.x * d.x + O.y * d.y + d.z)
    c = -1.0 + O.x^2 + O.y^2 - O.z^2 + 2.0 * O.z

    Δ = b^2 - 4.0*a*c
    if Δ <= 0.0
        return false
    end

    sqrot = sqrt(Δ)
    t1 = (-b - sqrot) / (2.0*a)
    t2 = (-b + sqrot) / (2.0*a)
    
    z1 = O.z + t1 * d.z
    z2 = O.z + t2 * d.z
    
    return (t1 > inv_ray.tmin && t1 < inv_ray.tmax && z1 > 0.0 && z1 < 1.0) || (t2 > inv_ray.tmin && t2 < inv_ray.tmax && z2 > 0.0 && z2 < 1.0)
end