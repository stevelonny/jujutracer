#---------------------------------------------------------
# HitRecord
#---------------------------------------------------------
"""
    struct SurfacePoint(u::Float64, v::Float64)

A struct representing a point on the surface of a shape in UV coordinates.
# Fields
- `u::Float64`, `v::Float64`: the UV coordinates of the point on the surface.
"""
struct SurfacePoint
    u::Float64
    v::Float64
end

"""
    struct HitRecord

Retains the information about the intersection between a ray and a shape.
# Fields
- `world_P::Point`: the world point of intersection.
- `normal::Normal`: the normal vector to the surface at the hit point.
- `surface_P::SurfacePoint`: the point on the shape's surface in UV coordinates.
- `t::Float64`: the distance from the ray origin to the hit point along the ray.
- `ray::Ray`: the ray that strikes the shape.
# Constructor
- `HitRecord(;world_P::Point, normal::Normal, surface_P::SurfacePoint, t::Float64, ray::Ray)`: creates a new `HitRecord` with the specified parameters.
# See also
- [`ray_intersection`](@ref): method to calculate the intersection of a ray with a shape.
- [`SurfacePoint`](@ref): the struct representing a point on the surface of a shape in UV coordinates.
- [`Ray`](@ref): the ray structure used in the intersection calculation.
- [`AbstractShape`](@ref): the abstract type for all shapes.
"""
struct HitRecord
    world_P::Point
    normal::Normal
    surface_P::SurfacePoint
    t::Float64
    ray::Ray

    function HitRecord(; world_P::Point, normal::Normal, surface_P::SurfacePoint, t::Float64, ray::Ray)
        new(world_P, normal, surface_P, t, ray)
    end

end

Base.:≈(h1::HitRecord, h2::HitRecord) = h1.world_P ≈ h2.world_P && h1.normal ≈ h2.normal && h1.surface_P ≈ h2.surface_P && h1.t ≈ h2.t && h1.ray ≈ h2.ray
Base.:≈(h::HitRecord, p::Point) = h.world_P ≈ p
Base.:≈(h::HitRecord, s::SurfacePoint) = h.surface_P ≈ s
Base.:≈(h::HitRecord, r::Ray) = h.ray ≈ r
Base.:≈(s1::SurfacePoint, s2::SurfacePoint) = s1.u ≈ s2.u && s1.v ≈ s2.v


#---------------------------------------------------------
# Shapes
#---------------------------------------------------------
"""
    abstract type AbstractShape

Abstract type for all shapes.
"""
abstract type AbstractShape end

"""
    abstract type AbstractSolid <: AbstractShape

Abstract type for solid shapes.
Made concrete by [`Sphere`](@ref).
"""
abstract type AbstractSolid <: AbstractShape end


#---------------------------------------------------------
# Sphere and methods
#---------------------------------------------------------

"""
    struct Sphere <: AbstractSolid

A sphere.
This structure is a subtype of [`AbstractSolid`](@ref).
# Fields
- `t::Transformation`: the transformation applied to the sphere.
"""
struct Sphere <: AbstractSolid
    Tr::AbstractTransformation

    function Sphere()
        new(Transformation())
    end
    function Sphere(Tr::AbstractTransformation)
        new(Tr)
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
        world_P=S.Tr(hit_point),
        normal=S.Tr(_sphere_normal(hit_point, ray.dir)),
        surface_P=_point_to_uv(S, hit_point),
        t=first_hit,
        ray=ray
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
        ray=ray
    )
    HR2 = HitRecord(
        world_P=S.Tr(hit_point_2),
        normal=S.Tr(_sphere_normal(hit_point_2, ray.dir)),
        surface_P=_point_to_uv(S, hit_point_2),
        t=second_hit,
        ray=ray
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
# Plane and methods
#---------------------------------------------------------

"""
    struct Plane <: AbstractShape

A plane.
This structure is a subtype of [`AbstractShape`](@ref).
# Fields
- `t::Transformation`: the transformation applied to the plane.
"""
struct Plane <: AbstractShape
    Tr::AbstractTransformation

    function Plane()
        new(Transformation())
    end
    function Plane(Tr::AbstractTransformation)
        new(Tr)
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
        world_P=pl.Tr(hit_point),
        normal=norm,
        surface_P=_point_to_uv(pl, hit_point),
        t=first_hit,
        ray=ray
    )
end

function internal(S::Plane, P::Point)
    return (inverse(S.Tr)(P).z <= 0.0) ? true : false
end

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