#---------------------------------------------------------
# Box
#---------------------------------------------------------

"""
    struct Box <: AbstractSolid

An axis-aligned box (rectangular cuboid) defined by two opposite corners.
# Fields
- `Tr::AbstractTransformation`: The transformation applied to the box.
- `P1::Point`: One corner of the box (minimum x, y, z).
- `P2::Point`: The opposite corner of the box (maximum x, y, z).
- `Mat::Material`: The material of the box.
# Constructors
- `Box()`: Creates a new box with default transformation and material.
- `Box(Tr::AbstractTransformation)`: Creates a new box with the specified transformation and default material.
- `Box(P1::Point, P2::Point)`: Creates a new box with the specified corners and default transformation and material.
- `Box(P1::Point, P2::Point, Mat::Material)`: Creates a new box with the specified corners and material.
- `Box(Tr::AbstractTransformation, P1::Point, P2::Point)`: Creates a new box with the specified transformation and corners.
- `Box(Tr::AbstractTransformation, P1::Point, P2::Point, Mat::Material)`: Creates a new box with the specified transformation, corners, and material.
- `Box(Mat::Material)`: Creates a new box with the default transformation and the specified material.
- `Box(Tr::AbstractTransformation, Mat::Material)`: Creates a new box with the specified transformation and material.
"""
struct Box <: AbstractSolid
    Tr::AbstractTransformation
    P1::Point
    P2::Point
    Mat::Material

    function Box()
        new(Transformation(), Point(-0.5, -0.5, -0.5), Point(0.5, 0.5, 0.5), Material())
    end
    function Box(P1::Point, P2::Point)
        new(Transformation(), _LFD(P1, P2), _RBU(P1, P2), Material())
    end
    function Box(Tr::AbstractTransformation)
        new(Tr, Point(-0.5, -0.5, -0.5), Point(0.5, 0.5, 0.5), Material())
    end
    function Box(Tr::AbstractTransformation, P1::Point, P2::Point)
        new(Tr, _LFD(P1, P2), _RBU(P1, P2), Material())
    end
    function Box(Tr::AbstractTransformation, P1::Point, P2::Point, Mat::Material)
        new(Tr, _LFD(P1, P2), _RBU(P1, P2), Mat)
    end
    function Box(P1::Point, P2::Point, Mat::Material)
        new(Transformation(), _LFD(P1, P2), _RBU(P1, P2), Mat)
    end
    function Box(Mat::Material)
        new(Transformation(), Point(-0.5, -0.5, -0.5), Point(0.5, 0.5, 0.5), Mat)
    end
    function Box(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Point(-0.5, -0.5, -0.5), Point(0.5, 0.5, 0.5), Mat)
    end
end

"""
    _LFD(P1::Point, P2::Point)

Return the corner of the box with the minimum x, y, z coordinates (Left, Front, Down).
"""
function _LFD(P1::Point, P2::Point)
    return Point(min(P1.x, P2.x), min(P1.y, P2.y), min(P1.z, P2.z))
end

"""
    _RBU(P1::Point, P2::Point)

Return the corner of the box with the maximum x, y, z coordinates (Right, Back, Up).
"""
function _RBU(P1::Point, P2::Point)
    return Point(max(P1.x, P2.x), max(P1.y, P2.y), max(P1.z, P2.z))
end

"""
    _point_to_uv(box::Box, p::Point, norm::Normal)

Calculate the UV coordinates of a point on the surface of a box, using the surface normal to determine which face is being mapped.
The UV mapping follows a cube-unwrapping scheme:
```
    +----+------+-----+----+
    |xxxx| Top  |xxxxxxxxxx|
    |xxxx| (Y+) |xxxxxxxxxx| 
2/3 +----+------+-----+----+
    |Left|Front |Right|Back|
    |(X-)|(Z+)  |(X+) |(Z-)|
1/3 +----+------+-----+----+
    |xxxx|Bottom|xxxxxxxxxx|
    |xxxx| (Y-) |xxxxxxxxxx|
    +----+------+-----+----+
```
# Arguments
- `box::Box`: The box shape.
- `p::Point`: The point on the box surface (in local box coordinates).
- `norm::Normal`: The untransformed normal at the point, used to determine which face is being mapped.
# Returns
- `SurfacePoint`: The UV coordinates `(u, v)` of the point on the box surface.
"""
function _point_to_uv(box::Box, p::Point, norm::Normal)
    # Transform point to box local space
    # Get box bounds
    p1, p2 = box.P1, box.P2

    # Normalize coordinates to [0,1] on each axis
    nx = (p.x - p1.x) / (p2.x - p1.x)
    ny = (p.y - p1.y) / (p2.y - p1.y)
    nz = (p.z - p1.z) / (p2.z - p1.z)
    quarter = 1.0 / 4.0
    tol = 1e-6
    if abs(norm.x - 1.0) < tol      # +X (Right)
        u = 0.5 + nz * 0.25
        v = quarter + (1.0 - ny) * quarter
    elseif abs(norm.x + 1.0) < tol # -X (Left)
        u = 0.0 + nz * 0.25
        v = quarter + (1.0 - ny) * quarter
    elseif abs(norm.y - 1.0) < tol  # +Y (Top)
        u = 0.25 + nx * 0.25
        v = 2.0 * quarter + (1.0 - nz) * quarter
    elseif abs(norm.y + 1.0) < tol # -Y (Bottom)
        u = 0.25 + nx * 0.25
        v = 0.0 + nz * quarter
    elseif abs(norm.z - 1.0) < tol  # +Z (Front)
        u = 0.25 + nx * 0.25
        v = quarter + (1.0 - ny) * quarter
    elseif abs(norm.z + 1.0) < tol # -Z (Back)
        u = 0.75 + (1.0 - nx) * 0.25
        v = quarter + (1.0 - ny) * quarter
    else
        u, v = 0.0, 0.0
    end
    return SurfacePoint(u, v)
end

"""
    ray_intersection(box::Box, ray::Ray)

Calculate the intersection of a ray and a box.
# Arguments
- `box::Box`: The box to be intersected.
- `ray::Ray`: The ray to intersect with the box.
# Returns
- `HitRecord`: The hit record of the first intersection, if any.
- `nothing`: If no intersection occurs.
"""
function ray_intersection(box::Box, ray::Ray)
    inv_ray = _unsafe_inverse(box.Tr)(ray)
    p1 = box.P1
    p2 = box.P2
    O = inv_ray.origin
    d = inv_ray.dir

    t1x = (p1.x - O.x) / d.x
    t2x = (p2.x - O.x) / d.x
    t1y = (p1.y - O.y) / d.y
    t2y = (p2.y - O.y) / d.y
    t1z = (p1.z - O.z) / d.z
    t2z = (p2.z - O.z) / d.z

    # more concise version but i dont really trust it
    tmin = max(min(t1x, t2x), min(t1y, t2y), min(t1z, t2z))
    tmax = min(max(t1x, t2x), max(t1y, t2y), max(t1z, t2z))
    if tmax < max(inv_ray.tmin, tmin)
        return nothing
    end
    first_hit = tmin > inv_ray.tmin ? tmin : tmax
    first_hit > inv_ray.tmax && return nothing

    hit_point = inv_ray(first_hit)
    # normal
    if first_hit == t1x || first_hit == t2x
        norm = Normal(-copysign(1.0, d.x), 0.0, 0.0)
    elseif first_hit == t1y || first_hit == t2y
        norm = Normal(0.0, -copysign(1.0, d.y), 0.0)
    else
        norm = Normal(0.0, 0.0, -copysign(1.0, d.z))
    end

    # point_to_uv needs the untransformed normal
    sur_point = _point_to_uv(box, hit_point, norm)
    norm = box.Tr(norm)
    return HitRecord(
        world_P=box.Tr(hit_point),
        normal=norm,
        surface_P=sur_point, #= _point_to_uv(box, hit_point) =#
        t=first_hit,
        ray=ray,
        shape=box
    )
end

"""
    internal(box::Box, P::Point)

Check if a point is inside the box.
# Arguments
- `box::Box`: The box to check.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the box, `false` otherwise.
"""
function internal(box::Box, P::Point)
    p = _unsafe_inverse(box.Tr)(P)
    cond_x = p.x <= box.P2.x && p.x >= box.P1.x
    cond_y = p.y <= box.P2.y && p.y >= box.P1.y
    cond_z = p.z <= box.P2.z && p.z >= box.P1.z

    return (cond_x && cond_y && cond_z) ? true : false
end

"""
    ray_intersection_list(box::Box, ray::Ray)

Calculate all intersections of a ray with a box.
# Arguments
- `box::Box`: The box to be intersected.
- `ray::Ray`: The ray to intersect with the box.
# Returns
- `Vector{HitRecord}`: A list of hit records for the two intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(box::Box, ray::Ray)
    inv_ray = _unsafe_inverse(box.Tr)(ray)
    p1 = box.P1
    p2 = box.P2
    O = inv_ray.origin
    d = inv_ray.dir

    t1x = (p1.x - O.x) / d.x
    t2x = (p2.x - O.x) / d.x
    t1y = (p1.y - O.y) / d.y
    t2y = (p2.y - O.y) / d.y
    t1z = (p1.z - O.z) / d.z
    t2z = (p2.z - O.z) / d.z

    tmin = max(min(t1x, t2x), min(t1y, t2y), min(t1z, t2z))
    tmax = min(max(t1x, t2x), max(t1y, t2y), max(t1z, t2z))
    if tmax < max(inv_ray.tmin, tmin) || tmax > inv_ray.tmax
        return nothing
    end
    if tmin < inv_ray.tmin || tmin > inv_ray.tmax
        return nothing
    end
    first_hit = tmin
    second_hit = tmax

    hit_point_1 = inv_ray(first_hit)
    hit_point_2 = inv_ray(second_hit)
    # normal
    if first_hit == t1x || first_hit == t2x
        norm1 = Normal(-copysign(1.0, d.x), 0.0, 0.0)
    elseif first_hit == t1y || first_hit == t2y
        norm1 = Normal(0.0, -copysign(1.0, d.y), 0.0)
    else
        norm1 = Normal(0.0, 0.0, -copysign(1.0, d.z))
    end
    if second_hit == t1x || second_hit == t2x
        norm2 = Normal(-copysign(1.0, d.x), 0.0, 0.0)
    elseif second_hit == t1y || second_hit == t2y
        norm2 = Normal(0.0, -copysign(1.0, d.y), 0.0)
    else
        norm2 = Normal(0.0, 0.0, -copysign(1.0, d.z))
    end

    # point_to_uv needs the untransformed normal
    sur_point_1 = _point_to_uv(box, hit_point_1, norm1)
    sur_point_2 = _point_to_uv(box, hit_point_2, norm2)
    norm1 = box.Tr(norm1)
    norm2 = box.Tr(norm2)
    HR1 = HitRecord(
        world_P=box.Tr(hit_point_1),
        normal=norm1,
        surface_P=sur_point_1, #= _point_to_uv(box, hit_point) =#
        t=first_hit,
        ray=ray,
        shape=box
    )
    HR2 = HitRecord(
        world_P=box.Tr(hit_point_2),
        normal=norm2,
        surface_P=sur_point_2, #= _point_to_uv(box, hit_point) =#
        t=second_hit,
        ray=ray,
        shape=box
    )
    return [HR1, HR2]
end

"""
    boxed(S::Box)::Tuple{Point, Point}

Returns the bounding box of the box.
# Arguments
- `S::Box`: The box for which to calculate the bounding box.
# Returns
- `Tuple{Point, Point}`: A tuple containing the two opposite corners of the bounding box of the box.
"""
function boxed(S::Box)::Tuple{Point,Point}
    # Thanks chatGPT
    # Get local-space corners
    p1, p2 = S.P1, S.P2
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