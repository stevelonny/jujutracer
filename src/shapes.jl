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
- `normal2::Normal` the normal vector at the second point of intersection
- `surface_P::SurfacePoint` the point on the surface where the ray hit
- `t::Float64` the distance from the ray origin to the hit point
- `t2::Float64` the distance from the ray origin to the second hit point
- `ray::Ray` the ray that hit the surface
"""
struct HitRecord
    world_P::Point    
    normal::Normal
    normal2::Normal
    surface_P::SurfacePoint
    t::Float64
    t2::Float64
    ray::Ray

    function HitRecord(; world_P::Point, normal::Normal, normal2::Normal,surface_P::SurfacePoint, t::Float64, t2::Float64,ray::Ray)
        new(world_P, normal, normal2, surface_P, t, t2, ray)
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

#---------------------------------------------------------
# Constructive Solid Geometry
#---------------------------------------------------------
"""
    union(Tr::Transformation, Sh1::AbstractShape, Sh2::AbstractShape)

Return the union (\\cap ) of `Sh1`and `Sh2`
"""
struct union <: AbstractShape
    Tr::AbstractTransformation
    Sh1::AbstractShape
    Sh2::AbstractShape
end

"""
    Difference(Tr::Transformation, Sh1::AbstractShape, Sh2::AbstractShape)

Return the difference `Sh1 - Sh2`
"""
struct Difference <: AbstractShape
    Tr::AbstractTransformation
    Sh1::AbstractShape
    Sh2::AbstractShape
end

"""
    Intersection(Tr::Transformation, Sh1::AbstractShape, Sh2::AbstractShape)

Return the intersection (\\cap ) of `Sh1`and `Sh2`
"""
struct Intersection <: AbstractShape
    Tr::AbstractTransformation
    Sh1::AbstractShape
    Sh2::AbstractShape
end

Base.:∪(S1::AbstractShape, S2::AbstractShape) = union(Transformation(), S1, S2)
Base.:-(S1::AbstractShape, S2::AbstractShape) = Difference(Transformation(), S1, S2)
Base.:∩(S1::AbstractShape, S2::AbstractShape) = Intersection(Transformation(), S1, S2)

"""
    ray_intersection(U::Union, ray::Ray)

Calculate the intersection of a ray and a union of shapes
# Arguments
- `U::Union` the union of shapes
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record of the shape fistly hitten if there is an intersection, nothing otherwise
"""
function ray_intersection(U::union, ray::Ray)
    HR1 = ray_intersection(U.Sh1, ray)
    HR2 = ray_intersection(U.Sh2, ray)

    if isnothing(HR1)
        if isnothing(HR2)
            return nothing
        else 
            return HR2
        end
    elseif isnothing(HR2)
        return HR1
    else
        return (HR1.t < HR2.t) ? HR1 : HR2
    end    
end

function internal(U::union, P::Point)
    p = inverse(U.Tr)(P) # P in the un-transofmed union system
    return internal(U.Sh1, p) || internal(U.Sh2, p) 
end

"""
    ray_intersection(U::Difference, ray::Ray)

Calculate the intersection of a ray and a difference of shapes
# Arguments
- `D::Difference` the difference of shapes
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record of the shape fistly hitten if there is an intersection, nothing otherwise
"""
function ray_intersection(D::Difference, ray::Ray)
    HR1 = ray_intersection(D.Sh1, ray)
    HR2 = ray_intersection(D.Sh2, ray)
   
    if isnothing(HR1) || isnothing(HR2)
        return HR1
    elseif HR1.t < HR2.t # && !internal(D.Sh2, HR1.world_P)
        return HitRecord(
            world_P = HR1.world_P,
            normal = HR1.normal,
            normal2 = (HR2.normal ⋅ ray.dir > 0.0) ? HR2.normal : - HR2.normal,
            surface_P = HR1.surface_P,
            t = HR1.t,
            t2 = HR2.t,
            ray = ray
        ) # HR1 but with exit point the one entering in Sh1
    elseif HR2.t < HR1.t && !internal(D.Sh1, HR2.world_P) && !internal(D.Sh1, ray(HR2.t2))
        return nothing
    else
        hit_point = (inverse(D.Sh2.Tr))(ray)(HR2.t2)
        return HitRecord(
            world_P = D.Sh2.Tr(hit_point),
            normal = (HR2.normal2 ⋅ ray.dir < 0) ? HR2.normal2 : - HR2.normal2,
            normal2 = (HR1.normal2 ⋅ ray.dir > 0) ? HR1.normal2 : - HR1.normal2,
            surface_P = _point_to_uv(D.Sh2, hit_point),
            t = HR2.t2,
            t2 = HR1.t2,
            ray = ray
        )
    end
end

function internal(D::Difference, P::Point)
    p = inverse(D.Tr)(P) # P in the un-transofmed difference system
    return internal(D.Sh1, p) && !internal(D.Sh2, p) 
end

"""
    ray_intersection(I::Intersection, ray::Ray)

Calculate the intersection of a ray and a union of shapes
# Arguments
- `U::Union` the intersection of shapes
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record of the shape fistly hitten if there is an intersection, nothing otherwise
"""
function ray_intersection(I::Intersection, ray::Ray)
    HR1 = ray_intersection(I.Sh1, ray)
    HR2 = ray_intersection(I.Sh2, ray)

    if isnothing(HR1) || isnothing(HR2)
        return nothing
    elseif HR2.t > HR1.t && internal(I.Sh1, HR2.world_P)
        return HitRecord(
            world_P = HR2.world_P,
            normal = HR2.normal,
            normal2 = (HR1.normal2 ⋅ ray.dir > 0.0) ? HR1.normal2 : - HR1.normal2,
            surface_P = HR2.surface_P,
            t = HR2.t,
            t2 = HR1.t2,
            ray = ray
        ) # HR2 but with the exit point of Sh1
    elseif HR1.t > HR2.t && internal(I.Sh2, HR1.world_P)
        return return HitRecord(
            world_P = HR1.world_P,
            normal = HR1.normal,
            normal2 = (HR2.normal2 ⋅ ray.dir > 0.0) ? HR2.normal2 : - HR2.normal2,
            surface_P = HR1.surface_P,
            t = HR1.t,
            t2 = HR2.t2,
            ray = ray
        ) # HR1 but with the exit point of Sh2
    else
        return nothing
    end        
end

function internal(I::Intersection, P::Point)
    p = inverse(I.Tr)(P) # P in the un-transofmed intersection system
    return internal(I.Sh1, p) && internal(I.Sh2, p) # da inserire la trasformation di I
end
#---------------------------------------------------------
# Sphere and methods
#---------------------------------------------------------

"""
    Sphere(Tr::Transformation)

A sphere shape
# Fields
- `Tr::Transformation` the transformation of the sphere
"""
struct Sphere <: AbstractShape
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

    _point_to_uv(S::Sphere, p::Point)

Calculate the UV coordinates of a point on the sphere
# Arguments
- `S::Sphere` the Sphere
- `p::Point` the point on the sphere
# Returns
- `SurfacePoint` the UV coordinates of the point on the sphere
"""
function _point_to_uv(S::Sphere, p::Point)
    return SurfacePoint(atan(p.y, p.x) / (2.0 * π), acos(p.z) / π)
end


""" 

    function ray_intersection(S::Sphere, ray::Ray)

Calculate the intersection of a ray and a sphere
# Arguments
- `S::Sphere` the sphere
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
"""
function ray_intersection(S::Sphere, ray::Ray)
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
        normal2 = S.Tr(_sphere_normal(inv_ray(t2), ray.dir)),
        surface_P = _point_to_uv(S, hit_point),
        t = first_hit,
        t2 = t2,
        ray = ray
    )
end

function internal(S::Sphere, P::Point)
    return (squared_norm(Vec(inverse(S.Tr)(P))) <= 1.0) ? true : false
end

#---------------------------------------------------------
# Plane and methods
#---------------------------------------------------------

"""
    Plane(Tr::Transformation)
A plane shape
# Fields
- `Tr::Transformation` the transformation of the plane
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

    _point_to_uv(S::Plane, p::Point)

Calculate the UV coordinates of a point on the plane in PBC
# Arguments
- `S::Plane` the plane
- `p::Point` the point on the plane
# Returns
- `SurfacePoint` the UV coordinates of the point in PBC
"""
function _point_to_uv(S::Plane, p::Point)
    return SurfacePoint(p.x - floor(p.x), p.y - floor(p.y))
end

"""

    ray_intersection(p::Plane, r::Ray)

Calculate the intersection of a ray and a plane
# Arguments
- `S::Plane` the plane
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
"""
function ray_intersection(pl::Plane, ray::Ray)
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
    norm = pl.Tr(_plane_normal(hit_point, ray.dir))
    return HitRecord(
        world_P = pl.Tr(hit_point),
        normal = norm,
        normal2 = norm, # arbitrarly chosen as second hit
        surface_P = _point_to_uv(pl, hit_point),
        t = first_hit,
        t2 = first_hit, # arbitrarly chosen as second hit
        ray = ray
    )
end

function internal(S::Plane, P::Point)
    return (inverse(S.Tr)(P).z <= 0.0) ? true : false
end

#---------------------------------------------------------
# Plane and methods
#---------------------------------------------------------

struct Square <: AbstractShape
    Tr::AbstractTransformation

    function Square(Tr::AbstractTransformation)
        P_front = Plane(Tr ⊙ Translation(-0.5, 0.0, 0.0) ⊙ Ry(π/2.0))
        P_back = Plane(Tr ⊙ Translation(0.5, 0.0, 0.0) ⊙ Ry(-π/2.0))
        P_up = Plane(Tr ⊙ Translation(0.0, 0.0, 0.5))
        P_down = Plane(Tr ⊙ Translation(0.0, 0.0, -0.5) ⊙ Ry(π))
        P_right = Plane(Tr ⊙ Translation(0.0, -0.5, 0.0) ⊙ Rx(-π/2.0))
        P_left = Plane(Tr ⊙ Translation(0.0, 0.5, 0.0) ⊙ Rx(π/2.0))
        return P_front ∩ P_back ∩ P_up ∩ P_down ∩ P_right ∩ P_left
    end

    function Square()
        Square(Transformation())
    end
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

    ray_intersection(W::World, ray::Ray)

Return the intersection between `ray` and the shapes in the `World`
# Arguments
- `W::World` the plane
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
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