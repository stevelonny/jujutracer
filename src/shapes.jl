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
    return SurfacePoint(atan(p.y, p.x) / (2.0 * π), acos(p.z) / π)
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
    Δrid = (O ⋅ d)^2 - squared_norm(d) * (squared_norm(O) - 1)

    if Δrid > 0
        sqrot = sqrt(Δrid)
        t1 = (-O ⋅ d - sqrot) / squared_norm(d)
        t2 = (-O ⋅ d + sqrot) / squared_norm(d)
        if t1 > inv_ray.tmin && t1 < inv_ray.tmax
            first_hit = t1
        elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax
            first_hit = t2
        else
            return nothing
        end
    else
        return nothing
    end

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
    Δrid = (O ⋅ d)^2 - squared_norm(d) * (squared_norm(O) - 1)

    if Δrid > 0
        sqrot = sqrt(Δrid)
        t1 = (-O ⋅ d - sqrot) / squared_norm(d)
        t2 = (-O ⋅ d + sqrot) / squared_norm(d)
        if t1 > inv_ray.tmin && t1 < inv_ray.tmax
            first_hit = t1
            second_hit = t2
        elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax
            first_hit = t2
            second_hit = t1
        else
            return nothing
        end
    else
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

#---------------------------------------------------------
# Box
#---------------------------------------------------------
"""
Left Front Down
"""
function _LFD(P1::Point, P2::Point)
    return Point(min(P1.x, p2.x), min(P1.y, P2.y), min(P1.z, P2.z))
end

"""
Right Back Up
"""
function _RBU(P1::Point, P2::Point)
    return Point(max(P1.x, p2.x), max(P1.y, P2.y), max(P1.z, P2.z))
end

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
end

function ray_intersection(box::Box, ray::Ray)
    inv_ray = inverse(box.Tr)(ray)
    p1 = box.P1
    p2 = box.P2
    O = inv_ray.origin
    d = inv_ray.dir

    # still to do
end

function internal(box::Box, P::Point)
    p = inverse(box.Tr)(P)
    cond_x = p.x <= box.P2.x && p.x >= box.P1.x
    cond_y = p.y <= box.P2.y && p.y >= box.P1.y
    cond_z = p.z <= box.P2.z && p.z >= box.P1.z

    return (cond_x && cond_y && cond_z) ? true : false
end

function ray_intersection_list(box::Box, ray::Ray)
    inv_ray = inverse(box.Tr)(ray)
    p1 = box.P1
    p2 = box.P2

    # still to do...
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

    if d != 0
        t = -Oz / d.z
        if t > inv_ray.tmin && t < inv_ray.tmax
            first_hit = t
        else
            return nothing
        end
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = pl.Tr(_plane_normal(hit_point, ray.dir))
    return HitRecord(
        world_P = pl.Tr(hit_point),
        normal = norm,
        surface_P = _point_to_uv(pl, hit_point),
        t = first_hit,
        ray = ray,
        shape = pl
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
        return Normal(0.0, 0.0, 1.0)
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

    if d != 0
        t = -O.z / d.z
        if t > inv_ray.tmin && t < inv_ray.tmax && abs(inv_ray(t).x) <= 0.5 && abs(inv_ray(t).y) <= 0.5 
            first_hit = t
        else
            return nothing
        end
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = S.Tr(_rectangle_normal(hit_point, ray.dir))
    return HitRecord(
        world_P = S.Tr(hit_point),
        normal = norm,
        surface_P = _point_to_uv(S, hit_point),
        t = first_hit,
        ray = ray,
        shape = S
    )
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

#---------------------------------------------------------
# BRDF Methods
#---------------------------------------------------------

"""
    Eval(BRDF::DiffusiveBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, p::SurfacePoint)

Return color of the diffused ray regarldless its icoming or outcoming direction.
"""
function Eval(BRDF::DiffusiveBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, p::SurfacePoint)
    return BRDF.Pigment(p) * BRDF.R / π
end 

function (U::UniformPigment)(p::SurfacePoint)
    return U.color
end

function (C::CheckeredPigment)(p::SurfacePoint)
    x = floor(Int, p.u * C.col)
    y = floor(Int, p.v * C.row)

    x = (x < C.col) ? x : C.col - 1
    y = (y < C.row) ? y : C.row - 1

    return ((x + y) % 2 == 0) ? C.dark : C.bright
end

function (I::ImagePigment)(p::SurfacePoint)
    x = floor(Int, p.u * I.img.w)
    y = floor(Int, p.v * I.img.h)

    x = (x < I.img.w) ? x : I.img.w - 1
    y = (y < I.img.h) ? y : I.img.h - 1

    return I.img[x, y]
end