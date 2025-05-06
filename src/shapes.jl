#---------------------------------------------------------
# HitRecord
#---------------------------------------------------------
struct SurfacePoint
    u::Float64
    v::Float64

    function SurfacePoint(u::Float64, v::Float64)
        new(u, v)
    end
end

"""

    HitRecord(world_point::Point, normal::Normal, surface_point::SurfacePoint, t::Float64, ray::Ray)

Information about an intersection
# Fields
- `world_point::Point` the point in the world where the ray hit
- `normal::Normal` the normal vector at the point of intersection
- `surface_point::SurfacePoint` the point on the surface where the ray hit
- `t::Float64` the distance from the ray origin to the hit point
- `ray::Ray` the ray that hit the surface
"""
struct HitRecord
    world_point::Point    
    normal::Normal
    surface_point::SurfacePoint
    t::Float64
    ray::Ray

    function HitRecord(world_point::Point, normal::Normal, surface_point::SurfacePoint, t::Float64, ray::Ray)
        new(world_point, normal, surface_point, t, ray)
    end

end

Base.:≈(h1::HitRecord, h2::HitRecord) = h1.world_point ≈ h2.world_point && h1.normal ≈ h2.normal && h1.surface_point ≈ h2.surface_point && h1.t ≈ h2.t && h1.ray ≈ h2.ray
Base.:≈(h::HitRecord, p::Point) = h.world_point ≈ p
Base.:≈(h::HitRecord, s::SurfacePoint) = h.surface_point ≈ s
Base.:≈(h::HitRecord, r::Ray) = h.ray ≈ r


#---------------------------------------------------------
#shapes
#---------------------------------------------------------
"""
    Shape

Abstract type for all shapes
"""
abstract type Shape end

#---------------------------------------------------------
#Sphere and methods
#---------------------------------------------------------

"""
    Sphere(radius::Float64, t::Transformation)

A sphere shape
# Fields
- `radius::Float64` the radius of the sphere
- `t::Transformation` the transformation of the sphere
"""
struct Sphere <: Shape
    t::Transformation
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
    return (to_vector(p) * dir < 0.0) ? norm : -norm
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
    return SurfacePoint(
    u=atan2(point.y, point.x) / (2.0 * pi),
    v=acos(point.z) / pi,
    )
end


""" 

    ray_intereption(s::Sphere, r::Ray)

Calculate the intersection of a ray and a sphere
# Arguments
- `s::Sphere` the sphere
- `r::Ray` the ray
# Returns
- `HitRecord` the hit record if there is an intersection, nothing otherwise
"""
function ray_intereption(s::Sphere, r::Ray)
    inv_ray = s.t.inv(r)
    origin_vec = to_vector(inv_ray.origin)

    a= squared_norm(inv_ray.dir)
    b= squared_norm(origin_vec)
    
    delta4_squared = sqrt( ( (origin_vec*inv_ray.dir)^2 - a * (b-1) )/4 )
    try 
        tmin= ( -origin_vec * inv_ray.dir - delta4_squared ) / a
        tmax= ( -origin_vec * inv_ray.dir + delta4_squared )  / a
    catch e
        #if here delta function is negative -> no intersection
        return nothing
    end

    if tmin > inv_ray.t_min && tmin < inv_ray.t_max
        first_hit = tmin
    elseif tmax > inv_ray.t_min && tmax < inv_ray.t_max
        first_hit = tmax
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_point = s.t( hit_point),  
        normal = s.t( _sphere_normal(hit_point, r.dir ) ),
        surface_point =  s.t( _sphere_point_to_uv(hit_point) ),
        t= first_hit,
        ray=r
    )
end




