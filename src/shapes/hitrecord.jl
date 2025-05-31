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