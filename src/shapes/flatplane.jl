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
    inv_ray = _unsafe_inverse(pl.Tr)(ray)
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

"""
    quick_ray_intersection(S::Plane, ray::Ray)::Bool
Checks if a ray intersects with the plane without calculating the exact intersection point.
# Arguments
- `S::Plane`: The plane to check for intersection.
- `ray::Ray`: The ray to check for intersection with the plane.
# Returns
- `Bool`: `true` if the ray intersects with the plane, `false` otherwise.
"""
function quick_ray_intersection(pl::Plane, ray::Ray)::Bool
    inv_ray = _unsafe_inverse(pl.Tr)(ray)
    Oz = inv_ray.origin.z
    d = inv_ray.dir

    t = -Oz / d.z
    if t > inv_ray.tmin && t < inv_ray.tmax
        return true
    else
        return false
    end
end