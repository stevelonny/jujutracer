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



