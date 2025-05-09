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
    Shape

Abstract type for all shapes
"""
abstract type AbstractShape end

"""
    ∩(S1::AbstractShape, S2::AbstractShape)

Rretrun the intersection between two shapes 
"""
function ∩(S1::AbstractShape, S2::AbstractShape)
    retu
end
#---------------------------------------------------------
# Sphere and methods
#---------------------------------------------------------

"""
    Sphere(t::Transformation)

A sphere shape
# Fields
- `t::Transformation` the transformation of the sphere
"""
struct Sphere <: AbstractShape
    Tr::AbstractTransformation
end

"""

    _sphere_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the sphere
# Arguments
- `p::Point` the point on the sphere
- `dir::Vec` the direction vector of the ray
# Returns
- `Normal` the normal vector of the sphere at the point
"""
function _sphere_normal(p::Point, dir::Vec )
    norm = Normal(p.x, p.y, p.z)
    return (Vec(p) ⋅ dir < 0.0) ? norm : -norm
end

"""

    _sphere_point_to_uv(p::Point)

Calculate the UV coordinates of a point on the sphere
# Arguments
- `p::Point` the point on the sphere
# Returns
- `SurfacePoint` the UV coordinates of the point on the sphere
"""
function _sphere_point_to_uv(p::Point)
    return SurfacePoint(atan(p.y, p.x) / (2.0 * π), acos(p.z) / π)
end


""" 

    ray_intereption(s::Sphere, r::Ray)

Calculate the intersection of a ray and a sphere
# Arguments
- `S::Sphere` the sphere
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
"""
function ray_interception(S::Sphere, ray::Ray)
    inv_ray = inverse(S.Tr)(ray)
    O = Vec(inv_ray.origin)
    d = inv_ray.dir
    Δrid = (O⋅d)^2 - squared_norm(d)*(squared_norm(O) - 1)

    if Δrid > 0
        sqrot = sqrt(Δrid)
        t1 = (- O⋅d - sqrot)/squared_norm(d)
        t2 = (- O⋅d + sqrot)/squared_norm(d)
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
        surface_P = _sphere_point_to_uv(hit_point),
        t = first_hit,
        ray = ray
    )
end

#---------------------------------------------------------
# Plane and methods
#---------------------------------------------------------

"""
    Plane(t::Transformation)
A plane shape
# Fields
- `t::Transformation` the transformation of the plane
"""
struct Plane <: AbstractShape
    Tr::AbstractTransformation
end

"""

    _plane_normal(p::Point, dir::Vec)

Calculate the normal vector of a point on the plane
# Arguments
- `p::Point` the point on the plane
- `dir::Vec` the direction vector of the ray
# Returns
- `Normal` the normal vector of the plane at the point
"""
function _plane_normal(p::Point, dir::Vec)
    norm = Normal(0.0, 0.0, 1.0)
    return (dir.z < 0.0) ? norm : -norm
end

"""

    _plane_point_to_uv(p::Point)

Calculate the UV coordinates of a point on the plane in PBC
# Arguments
- `p::Point` the point on the plane
# Returns
- `SurfacePoint` the UV coordinates of the point in PBC
"""
function _plane_point_to_uv(p::Point)
    return SurfacePoint(p.x - floor(p.x), p.y - floor(p.y))
end

"""

    ray_interception(p::Plane, r::Ray)

Calculate the intersection of a ray and a plane
# Arguments
- `S::Plane` the plane
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
"""
function ray_interception(pl::Plane, ray::Ray)
    inv_ray = inverse(pl.Tr)(ray)
    Oz = inv_ray.origin.z
    d = inv_ray.dir
    
    if d != 0
        t= -Oz\d.z
        if t > inv_ray.tmin && t < inv_ray.tmax
            first_hit = t
        else
            return nothing
        end
    else
        return nothing
    end
    
    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_P = pl.Tr(hit_point),
        normal = pl.Tr(_plane_normal(hit_point, ray.dir)),
        surface_P = _plane_point_to_uv(hit_point),
        t = first_hit,
        ray = ray
    )
end

#---------------------------------------------------------
# World type
#---------------------------------------------------------
"""

    struct World(shapes::Vector{AbstractShape})

The struct representig the scene
# Fields
- `shapes::Vector{AbstractShape}`
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

    ray_interception(W::World, ray::Ray)

Return the intersection between `ray` and the shapes in the `World`
# Arguments
- `W::World` the plane
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
"""
function ray_interception(W::World, ray::Ray)
    dim = length(W.shapes)
    closest = nothing

    for i in 1:dim
        inter = ray_interception(W.shapes[i], ray)
        if isnothing(inter)
            continue
        end
        if (isnothing(closest) || inter.t < closest.t)
            closest = inter
        end
    end

    return closest
end