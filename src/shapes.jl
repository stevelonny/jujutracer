#---------------------------------------------------------
# Shapes
#---------------------------------------------------------
"""
    abstract type AbstractShape

Abstract type for all shapes. Not guaranteed to be water-tight. Cannot be used to create CSG shapes.
"""
abstract type AbstractShape end

"""
    abstract type AbstractSolid <: AbstractShape

Abstract type for solid shapes. Considered water-tight. Can be used to create CSG shapes.
Made concrete by [`Sphere`](@ref).
"""
abstract type AbstractSolid <: AbstractShape end

#----------------------Solid shapes----------------------#

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
    inv_ray = inverse(S.Tr)(ray)
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
    inv_ray = inverse(S.Tr)(ray)
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
    if t1 > inv_ray.tmin && t1 < inv_ray.tmax
        first_hit = t1
        second_hit = t2
    elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax
        first_hit = t2
        second_hit = t1
    else
        return nothing
    end

    # when a ray is originated inside the sphere, the equation gives also the solution of the intersection in the opposite direction
    if signbit(first_hit) || signbit(second_hit)
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
    internal(S::Sphere, P::Point)

Checks if a point is inside a sphere.
# Arguments
- `S::Sphere`: The sphere to check.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the sphere, `false` otherwise.
"""
function internal(S::Sphere, P::Point)
    return (squared_norm(Vec(inverse(S.Tr)(P))) <= 1.0) ? true : false
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
    third = 1.0 / 3.0
    if !signbit(norm.x) # +X (Right)
        u = 0.5 + nz * 0.25
        v = third + (1.0 - ny) * third
    elseif signbit(norm.x) # -X (Left)
        u = 0.0 + nz * 0.25
        v = third + (1.0 - ny) * third
    elseif !signbit(norm.y)  # +Y (Top)
        u = 0.25 + nx * 0.25
        v = 2.0 * third + (1.0 - nz) * third
    elseif signbit(norm.y) # -Y (Bottom)
        u = 0.25 + nx * 0.25
        v = 0.0 + nz * third
    elseif !signbit(norm.z)  # +Z (Front)
        u = 0.25 + nx * 0.25
        v = third + (1.0 - ny) * third
    elseif signbit(norm.z) # -Z (Back)
        u = 0.75 + (1.0 - nx) * 0.25
        v = third + (1.0 - ny) * third
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
    inv_ray = inverse(box.Tr)(ray)
    p1 = box.P1
    p2 = box.P2
    O = inv_ray.origin
    d = inv_ray.dir

    # we need to make this function very fast: must be branchless
    # precompute some values? inverse ray dir?
    # reminder: to check if d is zero. There's no need to do it cause julia knows that 1 / 0 = Inf
    # reminder: check ray.tmin ray.tmax

    # first check x and y planes
    t1x = (p1.x - O.x) / d.x
    t2x = (p2.x - O.x) / d.x
    #txmin = min(t1x, t2x)
    #txmax = max(t1x, t2x)

    t1y = (p1.y - O.y) / d.y
    t2y = (p2.y - O.y) / d.y
    #tymin = min(t1y, t2y)
    #tymax = max(t1y, t2y)

    #if txmin > tymax || tymin > txmax
    #    return nothing
    #end
    #tmin = max(txmin, tymin)
    #tmax = min(txmax, tymax)

    # then check z planes
    t1z = (p1.z - O.z) / d.z
    t2z = (p2.z - O.z) / d.z
    #tzmin = min(t1z, t2z)
    #tzmax = max(t1z, t2z)

    #if tmin > tzmax || tzmin > tmax
    #    return nothing
    #end

    # more concise version but i dont really trust it
    tmin = max(min(t1x, t2x), min(t1y, t2y), min(t1z, t2z))
    tmax = min(max(t1x, t2x), max(t1y, t2y), max(t1z, t2z))
    if tmax < max(inv_ray.tmin, tmin)
        return nothing
    end
    first_hit = tmin > inv_ray.tmin ? tmin : tmax
    first_hit > inv_ray.tmax && return nothing

    #tmin = max(tmin, tzmin)
    #tmax = min(tmax, tzmax)

    #if tmin > inv_ray.tmin && tmax < inv_ray.tmax
    #    first_hit = tmin
    #elseif tmax > inv_ray.tmin && tmax < inv_ray.tmax
    #    first_hit = tmax
    #else
    #    return nothing
    #end

    # still to do: _box_normal and _point_to_uv

    hit_point = inv_ray(first_hit)
    # normal
    if first_hit == t1x || first_hit == t2x
        norm = Normal(-sign(d.x), 0.0, 0.0)
    elseif first_hit == t1y || first_hit == t2y
        norm = Normal(0.0, -sign(d.y), 0.0)
    else
        norm = Normal(0.0, 0.0, -sign(d.z))
    end

    # point_to_uv needs the untransformed normal
    sur_point = _point_to_uv(box, hit_point, norm)

    norm = box.Tr(norm)

    return HitRecord(
        world_P = box.Tr(hit_point),
        normal = norm,
        surface_P = sur_point, #= _point_to_uv(box, hit_point) =#
        t = first_hit,
        ray = ray,
        shape = box
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
    p = inverse(box.Tr)(P)
    cond_x = p.x < box.P2.x && p.x > box.P1.x
    cond_y = p.y < box.P2.y && p.y > box.P1.y
    cond_z = p.z < box.P2.z && p.z > box.P1.z

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
    inv_ray = inverse(box.Tr)(ray)
    p1 = box.P1
    p2 = box.P2
    O = inv_ray.origin
    d = inv_ray.dir

    # we need to make this function very fast: must be branchless
    # precompute some values? inverse ray dir?
    # reminder: to check if d is zero. There's no need to do it cause julia knows that 1 / 0 = Inf
    # reminder: check ray.tmin ray.tmax

    # first check x and y planes
    t1x = (p1.x - O.x) / d.x
    t2x = (p2.x - O.x) / d.x
    #txmin = min(t1x, t2x)
    #txmax = max(t1x, t2x)    

    t1y = (p1.y - O.y) / d.y
    t2y = (p2.y - O.y) / d.y
    #tymin = min(t1y, t2y)
    #tymax = max(t1y, t2y)

    #if txmin > tymax || tymin > txmax
    #    return nothing
    #end
    #tmin = max(txmin, tymin)
    #tmax = min(txmax, tymax)

    # then check z planes
    t1z = (p1.z - O.z) / d.z
    t2z = (p2.z - O.z) / d.z
    #tzmin = min(t1z, t2z)
    #tzmax = max(t1z, t2z)

    #if tmin > tzmax || tzmin > tmax
    #    return nothing
    #end

    # more concise version but i dont really trust it
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
        norm1 = Normal(-sign(d.x), 0.0, 0.0)
    elseif first_hit == t1y || first_hit == t2y
        norm1 = Normal(0.0, -sign(d.y), 0.0)
    else
        norm1 = Normal(0.0, 0.0, -sign(d.z))
    end
    if second_hit == t1x || second_hit == t2x
        norm2 = Normal(-sign(d.x), 0.0, 0.0)
    elseif second_hit == t1y || second_hit == t2y
        norm2 = Normal(0.0, -sign(d.y), 0.0)
    else
        norm2 = Normal(0.0, 0.0, -sign(d.z))
    end

    # point_to_uv needs the untransformed normal
    sur_point_1 = _point_to_uv(box, hit_point_1, norm1)
    sur_point_2 = _point_to_uv(box, hit_point_2, norm2)
    norm1 = box.Tr(norm1)
    norm2 = box.Tr(norm2)

    HR1 = HitRecord(
        world_P = box.Tr(hit_point_1),
        normal = norm1,
        surface_P = sur_point_1, #= _point_to_uv(box, hit_point) =#
        t = first_hit,
        ray = ray,
        shape = box
    )
    HR2 = HitRecord(
        world_P = box.Tr(hit_point_2),
        normal = norm2,
        surface_P = sur_point_2, #= _point_to_uv(box, hit_point) =#
        t = second_hit,
        ray = ray,
        shape = box
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
function boxed(S::Box)::Tuple{Point, Point}
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

#---------------------------------------------------------
# Cylinder
#---------------------------------------------------------

"""
    struct Cylinder <: AbstractSolid

A cylinder of unitary radiuos and height centered in the origin.
This structure is a subtype of [`AbstractSolid`](@ref).
# Fields
- `Tr::Transformation`: the transformation applied to the sphere.
- `Mat::Material`: the material of the shape
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
    return SurfacePoint(0.5 + atan(p.y, p.x) / (2.0 * π), p.z + 0.5)
end

"""
    ray_intersection(s::Cylinder, r::Ray)

Calculates the intersection of a ray and a sphere.
# Arguments
- `S::Cylinder`: the sphere to be intersected
- `ray::Ray`: the ray intersecting the sphere
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(S::Cylinder, ray::Ray)
    inv_ray = inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    # precompute common values, probably not needed as the compiler is already smart enough
    O_dot_d = O.x * d.x + O.y * d.y 
    d_squared = d.x^2 + d.y^2
    O_squared = O.x^2 + O.y^2

    Δrid = O_dot_d * O_dot_d - d_squared * (O_squared - 1.0)
    
    (Δrid <= 0.0 && d_squared != 0.0) && return nothing
    
    t1z = (0.5 - O.z)/d.z
    t2z = (-0.5 - O.z)/d.z
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

    # point in the sphere's local coordinates
    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_P = S.Tr(hit_point),
        normal = S.Tr(_sphere_normal(hit_point, ray.dir)),
        surface_P = _point_to_uv(S, hit_point),
        t = first_hit,
        ray = ray,
        shape = S
    )
end

"""
    ray_intersection_list(S::Cylinder, ray::Ray)

Calculates all intersections of a ray with a sphere.
# Arguments
- `S::Cylinder`: The sphere to be intersected.
- `ray::Ray`: The ray intersecting the sphere.
# Returns
- `Vector{HitRecord}`: A list of of the two hit records for the two intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(S::Cylinder, ray::Ray)
    inv_ray = inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir

    O_dot_d = O.x * d.x + O.y * d.y 
    d_squared = d.x^2 + d.y^2
    O_squared = O.x^2 + O.y^2

    Δrid = (O_dot_d)^2 - d_squared * (O_squared - 1)

    (Δrid <= 0.0 && d_squared != 0.0) && return nothing
    
    t1z = (0.5 - O.z)/d.z
    t2z = (-0.5 - O.z)/d.z
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

    hit_point_1 = inv_ray(first_hit)
    hit_point_2 = inv_ray(second_hit)
    HR1 = HitRecord(
        world_P = S.Tr(hit_point_1),
        normal = S.Tr(_sphere_normal(hit_point_1, ray.dir)),
        surface_P = _point_to_uv(S, hit_point_1),
        t = first_hit,
        ray = ray,
        shape = S
    )
    HR2 = HitRecord(
        world_P = S.Tr(hit_point_2),
        normal = S.Tr(_sphere_normal(hit_point_2, ray.dir)),
        surface_P = _point_to_uv(S, hit_point_2),
        t = second_hit,
        ray = ray,
        shape = S
    )
    return [HR1, HR2]
end

"""
    internal(S::Cylinder, P::Point)

Checks if a point is inside a sphere.
# Arguments
- `S::Cylinder`: The sphere to check.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the sphere, `false` otherwise.
"""
function internal(S::Cylinder, P::Point)
    p = inverse(S.Tr)(P)
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
function boxed(S::Cylinder)::Tuple{Point, Point}
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
    # if p.z = ± 0.5 than the normal is vertical, 
    # else if the point lies on the curve surface the normal is radial
    norm = Normal(p.x * (0.25 - p.z^2), p.y * (0.25 - p.z^2), 1.0 * (1.0 - (p.x^2 + p.y^2)))
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

Calculates the intersection of a ray and a sphere.
# Arguments
- `S::Cone`: the sphere to be intersected
- `ray::Ray`: the ray intersecting the sphere
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(S::Cone, ray::Ray)
    inv_ray = inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    # z = 1 - sqrt(x^2 + y^2)
    # (z - 1)^2 = x^2 + y^2
    # ... check minus signs
    a = d.x^2 + d.y^2 - d.z^2
    b = 2.0 * (-O.z * d.z + O.x * d.x + O.y * d.y + d.z)
    c = -1.0 + O.x^2 + O.y^2 - O.z^2 + 2.0 * O.z

    Δ = b^2 - 4.0*a*c
    Δ <= 0.0 && return nothing

#=     if Δ < 0.0
        if d.z ≈ 0.0
            return nothing # ray is parallel to the cone axis
        end
        tz = -O.z / d.z
        hit_base = inv_ray(tz)
        if tz > inv_ray.tmin && tz < inv_ray.tmax && hit_base.x^2 + hit_base.y^2 <= 1.0
            return HitRecord(
                world_P = S.Tr(hit_base),
                normal = S.Tr(_circle_normal(hit_base, ray.dir)),
                surface_P = _circle_point_to_uv(hit_base),
                t = tz,
                ray = ray,
                shape = S
            )
        else
            return nothing
        end
    end =#

    sqrot = sqrt(Δ)
    t1 = (-b - sqrot) / (2.0*a)
    t2 = (-b + sqrot) / (2.0*a)
    z1 = O.z + t1 * d.z
    z2 = O.z + t2 * d.z
    tz = -O.z / d.z
    hit_base = inv_ray(tz)
    if t1 > inv_ray.tmin && t1 < inv_ray.tmax && z1 > 0.0 && z1 < 1.0
        first_hit = t1
        if tz < t1 && tz > inv_ray.tmin && tz < inv_ray.tmax && hit_base.x^2 + hit_base.y^2 <= 1.0
            # if the base is hit before the first intersection, we return the base hit
            return HitRecord(
                world_P = S.Tr(hit_base),
                normal = S.Tr(_circle_normal(hit_base, ray.dir)),
                surface_P = _circle_point_to_uv(hit_base),
                t = tz,
                ray = ray,
                shape = S
            )
        end
    elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax && z2 > 0.0 && z2 < 1.0
        first_hit = t2
        if tz < t2 && tz > inv_ray.tmin && tz < inv_ray.tmax && hit_base.x^2 + hit_base.y^2 <= 1.0
            # if the base is hit before the first intersection, we return the base hit
            return HitRecord(
                world_P = S.Tr(hit_base),
                normal = S.Tr(_circle_normal(hit_base, ray.dir)),
                surface_P = _circle_point_to_uv(hit_base),
                t = tz,
                ray = ray,
                shape = S
            )
        end
    elseif tz > inv_ray.tmin && tz < inv_ray.tmax && hit_base.x^2 + hit_base.y^2 < 1.0
        # if the base is hit before the first intersection, we return the base hit
        return HitRecord(
            world_P = S.Tr(hit_base),
            normal = S.Tr(_circle_normal(hit_base, ray.dir)),
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
        normal = S.Tr(_cone_normal(hit_point, ray.dir)),
        surface_P = _point_to_uv(S, hit_point),
        t = first_hit,
        ray = ray,
        shape = S
    )
end

"""
    ray_intersection_list(S::Cone, ray::Ray)

Calculates all intersections of a ray with a sphere.
# Arguments
- `S::Cone`: The sphere to be intersected.
- `ray::Ray`: The ray intersecting the sphere.
# Returns
- `Vector{HitRecord}`: A list of of the two hit records for the two intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(S::Cone, ray::Ray)
    O = Vec(ray.origin)
    d = ray.dir
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
    hit_base = ray(tz)
    if tz > ray.tmin && tz < ray.tmax && hit_base.x^2 + hit_base.y^2 < 1.0
        HR_base = HitRecord(
            world_P = S.Tr(hit_base),
            normal = S.Tr(_circle_normal(hit_base, ray.dir)),
            surface_P = _circle_point_to_uv(hit_base),
            t = tz,
            ray = ray,
            shape = S
        )
        push!(hit_records, HR_base)
    end
    if t1 > ray.tmin && t1 < ray.tmax && z1 > 0.0 && z1 < 1.0
        HR1 = HitRecord(
            world_P = S.Tr(ray(t1)),
            normal = S.Tr(_cone_normal(ray(t1), ray.dir)),
            surface_P = _point_to_uv(S, ray(t1)),
            t = t1,
            ray = ray,
            shape = S
        )
        push!(hit_records, HR1)
    end
    if t2 > ray.tmin && t2 < ray.tmax && z2 > 0.0 && z2 < 1.0
        HR2 = HitRecord(
            world_P = S.Tr(ray(t2)),
            normal = S.Tr(_cone_normal(ray(t2), ray.dir)),
            surface_P = _point_to_uv(S, ray(t2)),
            t = t2,
            ray = ray,
            shape = S
        )
        push!(hit_records, HR2)
    end
    sort!(hit_records, by = h -> h.t)  # sort by distance
    if length(hit_records) == 0
        return nothing
    end
    return [hit_records[2], hit_records[1]]  # return the first two hits, if they exists
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
# Solid shapes are water-tight, and can be used to create CSG shapes.

#---------------------------------------------------------
# New Solid Shape and methods
#---------------------------------------------------------
# Remember to add docstrings and tests for the new solid shape
#=
struct NewSolid <: AbstractSolid
    Tr::AbstractTransformation
    Mat::Material

    function NewSolid()
        new(Transformation(), Material())
    end
    function NewSolid(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function NewSolid(Mat::Material)
        new(Transformation(), Mat)
    end
    function NewSolid(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end
=#

# _newsolid_normal(p::Point, dir::Vec)
# _point_to_uv(S::NewSolid, p::Point)
# ray_intersection(S::NewSolid, ray::Ray)
# ray_intersection_list(S::NewSolid, ray::Ray)
# internal(S::NewSolid, P::Point)

#----------------------Other shapes----------------------#

#---------------------------------------------------------
# Plane and methods
#---------------------------------------------------------

"""
    struct Plane <: AbstractShape

A plane.
This structure is a subtype of [`AbstractShape`](@ref).
# Fields
- `t::Transformation`: the transformation applied to the plane
- `Mat::Material`: the material of the shape
"""
struct Plane <: AbstractShape
    Tr::AbstractTransformation
    Mat::Material
    # add constructor including material: need standard material
    function Plane()
        new(Transformation(), Material())
    end
    function Plane(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function Plane(Mat::Material)
        new(Transformation(), Mat)
    end
    function Plane(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end

"""
    _plane_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the plane
# Arguments
- `p::Point`: the point on the plane.
- `dir::Vec`: the direction vector of the ray.
# Returns
- `Normal`: the normal to the plane's surface at the point.
"""
function _plane_normal(p::Point, dir::Vec)
    norm = Normal(0.0, 0.0, 1.0)
    return (dir.z < 0.0) ? norm : -norm
end

"""
    _point_to_uv(S::Plane, p::Point)

Calculate the UV coordinates of a point on the plane in PBC
# Arguments
- `p::Point`: the point on the plane
# Returns
- `SurfacePoint`: the UV coordinates of the point in PBC
"""
function _point_to_uv(S::Plane, p::Point)
    return SurfacePoint(p.x - floor(p.x), p.y - floor(p.y))
end

"""
    ray_intersection(p::Plane, r::Ray)

Calculate the intersection of a ray and a plane.
# Arguments
- `S::Plane`: the plane to be intersected.
- `ray::Ray`: the ray intersecting the plane.
# Returns
- `HitRecord`: The hit record of the first shape hit, if any.
- `nothing`: If no intersections occur.
"""
function ray_intersection(pl::Plane, ray::Ray)
    inv_ray = inverse(pl.Tr)(ray)
    Oz = inv_ray.origin.z
    d = inv_ray.dir

    t = -Oz / d.z
    if t > inv_ray.tmin && t < inv_ray.tmax
        first_hit = t
    else
        return nothing
    end


    hit_point = inv_ray(first_hit)
    norm = pl.Tr(_plane_normal(hit_point, ray.dir))
    return HitRecord(
        world_P=pl.Tr(hit_point),
        normal=norm,
        surface_P=_point_to_uv(pl, hit_point),
        t=first_hit,
        ray=ray,
        shape=pl
    )
end

#---------------------------------------------------------
# Rectangle
#---------------------------------------------------------
"""
    struct Rectangle <: AbstractShape

1x1 Rectangle on xy plane, centered in the origin
# Fields
- `t::Transformation`: the transformation applied to the plane
- `Mat::Material`: the material of the shape
"""
struct Rectangle <: AbstractShape
    Tr::AbstractTransformation
    Mat::Material

    function Rectangle()
        new(Transformation(), Material())
    end
    function Rectangle(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function Rectangle(Mat::Material)
        new(Transformation(), Mat)
    end
    function Rectangle(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end

"""
    _rectangle_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the rectangle
# Arguments
- `p::Point`: the point on the rectangle.
- `dir::Vec`: the direction vector of the ray.
# Returns
- `Normal`: the normal to the rectangle's surface at the point.
"""
function _rectangle_normal(p::Point, dir::Vec)
    if abs(p.x) > 0.5 || abs(p.y) > 0.5
        throw(ArgumentError("Point outside the rectangle"))
    else
        norm = Normal(0.0, 0.0, 1.0)
        return (dir.z < 0.0) ? norm : -norm
    end
end

"""
 _point_to_uv(S::Rectangle, p::Point)

Calculate the UV coordinates of a point on the plane in PBC
# Arguments
- `p::Point`: the point on the rectangle
# Returns
- `SurfacePoint`: the UV coordinates of the point in PBC
"""
function _point_to_uv(S::Rectangle, p::Point)
    if abs(p.x) > 0.5 || abs(p.y) > 0.5
        throw(ArgumentError("Point outside the rectangle"))
    else
        return SurfacePoint(p.x + 0.5, p.y + 0.5)
    end
end

"""
    ray_intersection(S::Rectangle, r::Ray)

Calculate the intersection of a ray and a plane.
# Arguments
- `S::Rectangle`: the rectangle to be intersected.
- `ray::Ray`: the ray intersecting the rectangle.
# Returns
- `HitRecord`: The hit record of the first shape hit, if any.
- `nothing`: If no intersections occur.
"""
function ray_intersection(S::Rectangle, ray::Ray)
    inv_ray = inverse(S.Tr)(ray)
    O = inv_ray.origin
    d = inv_ray.dir


    t = -O.z / d.z
    if t > inv_ray.tmin && t < inv_ray.tmax && abs(inv_ray(t).x) <= 0.5 && abs(inv_ray(t).y) <= 0.5
        first_hit = t
    else
        return nothing
    end


    hit_point = inv_ray(first_hit)
    norm = S.Tr(_rectangle_normal(hit_point, ray.dir))
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
    boxed(S::Rectangle)::Tuple{Point, Point}

Returns the bounding box of the rectangle.
# Arguments
- `S::Rectangle`: The rectangle for which to calculate the bounding box.
# Returns
- `Tuple{Point, Point}`: A tuple containing the two opposite corners of the bounding box of the rectangle.
"""
function boxed(S::Rectangle)::Tuple{Point, Point}
    # return P1 and P2 of the bounding box of the rectangle
    # remember to apply the transformation to the points
    p1 = Point(-0.5, -0.5, 0.0)
    p2 = Point(0.5, 0.5, 0.0)
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
    if p.x^2 + p.y^2 > 1.0
        throw(ArgumentError("Point outside the circle"))
    else
        norm = Normal(0.0, 0.0, 1.0)
        return (dir.z < 0.0) ? norm : -norm
    end
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
    r = sqrt(p.x^2 + p.y^2)
    θ = atan(p.y, p.x)
    u = θ / (2.0 * π) + 0.5
    v = r
    return SurfacePoint(u, v)
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
    inv_ray = inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir

    t = -O.z / d.z
    if t > inv_ray.tmin && t < inv_ray.tmax && (inv_ray(t).x^2 + inv_ray(t).y^2) <= 1.0
        first_hit = t
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = S.Tr(_circle_normal(hit_point, ray.dir))
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
function boxed(S::Circle)::Tuple{Point, Point}
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

# AbstractShape is not guaranteed to be water-tight, and cannot be used to create CSG shapes. (for now)
# For example, a plane is not water-tight.

#---------------------------------------------------------
# New Shape
#---------------------------------------------------------
# Remember to add docstrings and tests for the new solid shape
#=
struct NewShape <: AbstractShape
    Tr::AbstractTransformation
    Mat::Material

    function NewShape()
        new(Transformation(), Material())
    end
    function NewShape(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function NewShape(Mat::Material)
        new(Transformation(), Mat)
    end
    function NewShape(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end
=#

# _newshape_normal(p::Point, dir::Vec)
# _point_to_uv(S::NewShape, p::Point)
# ray_intersection(S::NewShape, ray::Ray)


#---------------------------------------------------------
# World type
#---------------------------------------------------------
"""
    struct World

A struct representing a collection of shapes in a 3D world.
# Fields
- `shapes::Vector{Shapes}`: the vector containing the shapes in the world.
# Constructor
- `World()`: creates a new `World` with an empty vector of shapes.
- `World(S::Vector{Shapes})`: creates a new `World` with the specified vector of shapes.
# See also
- [`AbstractShape`](@ref): the abstract type for all shapes.
- [`Sphere`](@ref): a concrete implementation of `AbstractShape` representing a sphere.
- [`Plane`](@ref): a concrete implementation of `AbstractShape` representing a plane.
"""
struct World
    shapes::Vector{AbstractShape}

    function World()
        new(Vector{AbstractShape}(nothing))
    end

    function World(S::Vector{AbstractShape})
        new(S)
    end
end

"""
    ray_intersection(W::World, ray::Ray)

Calculates the intersection of a ray with all shapes in the world.
# Arguments
- `W::World`: the world containing the shapes
- `ray::Ray`: the ray to be intersected with the shapes in the worlds
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(W::World, ray::Ray)
    dim = length(W.shapes)
    closest = nothing

    for i in 1:dim
        inter = ray_intersection(W.shapes[i], ray)
        if isnothing(inter)
            continue
        end
        if (isnothing(closest) || inter.t < closest.t)
            closest = inter
        end
    end

    return closest
end

#---------------------------------------------------------
# HitRecord
#---------------------------------------------------------
"""
    struct SurfacePoint

A struct representing a point on the surface of a shape.
# Fields
- `u::Float64`, `v::Float64: the (u,v) coordinates of the point on the surface.
"""
struct SurfacePoint
    u::Float64
    v::Float64
end

"""
    HitRecord(world_point::Point, normal::Normal, surface_point::SurfacePoint, t::Float64, ray::Ray)

Information about an intersection
# Fields
- `world_P::Point` the point in the world where the ray hit
- `normal::Normal` the normal vector at the point of intersection
- `surface_P::SurfacePoint` the point on the surface where the ray hit
- `t::Float64` the distance from the ray origin to the hit point
- `ray::Ray` the ray that hit the surface
"""
struct HitRecord
    world_P::Point
    normal::Normal
    surface_P::SurfacePoint
    t::Float64
    ray::Ray
    shape::AbstractShape

    function HitRecord(; world_P::Point, normal::Normal, surface_P::SurfacePoint, t::Float64, ray::Ray, shape::AbstractShape)
        new(world_P, normal, surface_P, t, ray, shape)
    end

end

Base.:≈(h1::HitRecord, h2::HitRecord) = h1.world_P ≈ h2.world_P && h1.normal ≈ h2.normal && h1.surface_P ≈ h2.surface_P && h1.t ≈ h2.t && h1.ray ≈ h2.ray
Base.:≈(h::HitRecord, p::Point) = h.world_P ≈ p
Base.:≈(h::HitRecord, s::SurfacePoint) = h.surface_P ≈ s
Base.:≈(h::HitRecord, r::Ray) = h.ray ≈ r
Base.:≈(s1::SurfacePoint, s2::SurfacePoint) = s1.u ≈ s2.u && s1.v ≈ s2.v