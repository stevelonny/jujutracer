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
    norm = Normal(0.0, 0.0, 1.0)
    return (dir.z < 0.0) ? norm : -norm
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
    return SurfacePoint(p.x + 0.5, p.y + 0.5)
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
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = inv_ray.origin
    d = inv_ray.dir


    t = -O.z / d.z
    if t > inv_ray.tmin && t < inv_ray.tmax && abs(inv_ray(t).x) <= 0.5 && abs(inv_ray(t).y) <= 0.5
        first_hit = t
    else
        return nothing
    end


    hit_point = inv_ray(first_hit)
    norm = S.Tr(_rectangle_normal(hit_point, d))
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
function boxed(S::Rectangle)::Tuple{Point,Point}
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


"""
    quick_ray_intersection(S::Rectangle, ray::Ray)::Bool
Checks if a ray intersects with the rectangle without calculating the exact intersection point.
# Arguments
- `S::Rectangle`: The triangle to check for intersection.
- `ray::Ray`: The ray to check for intersection with the triangle.
# Returns
- `Bool`: `true` if the ray intersects with the triangle, `false` otherwise.
"""
function quick_ray_intersection(S::Rectangle, ray::Ray)::Bool
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = inv_ray.origin
    d = inv_ray.dir

    t = -O.z / d.z
    if t <= inv_ray.tmin || t >= inv_ray.tmax || abs(inv_ray(t).x) > 0.5 || abs(inv_ray(t).y) > 0.5
        return false
    else
        return true
    end
end