#---------------------------------------------------------
# AABB
#---------------------------------------------------------

"""
    struct AABB <: AbstractShape

Axis-Aligned Bounding Box (AABB) for a set of shapes.
# Fields
- `S::Vector{AbstractShape}`: the vector of shapes contained within the AABB.
- `P1::Point`: the minimum corner of the AABB.
- `P2::Point`: the maximum corner of the AABB.
# Constructor
- `AABB(S::Vector{AbstractShape})`: creates an AABB for the shapes in `S`, calculating the minimum and maximum corners based on the bounding boxes of the shapes.
- `AABB(S::Vector{AbstractShape}, P1::Point, P2::Point)`: creates an AABB with the specified minimum and maximum corners `P1` and `P2` for the shapes in `S`.
- `AABB(csg::Union{CSGDifference, CSGUnion, CSGIntersection})`: creates an AABB for a CSG shape, extracting the shapes and their bounding box.
"""
struct AABB <: AbstractShape
    # no need for a transformation, the AABB is always axis aligned
    S::Vector{AbstractShape}
    P1::Point
    P2::Point

    function AABB(S::Vector{AbstractShape})
        if isempty(S)
            throw(ArgumentError("Cannot create AABB with an empty set of shapes."))
        end
        P1 = Point(Inf, Inf, Inf)
        P2 = Point(-Inf, -Inf, -Inf)
        for s in S
            p1, p2 = boxed(s)
            P1 = Point(min(P1.x, p1.x), min(P1.y, p1.y), min(P1.z, p1.z))
            P2 = Point(max(P2.x, p2.x), max(P2.y, p2.y), max(P2.z, p2.z))
        end
        new(S, P1, P2)
    end
    function AABB(S::Vector{AbstractShape}, P1::Point, P2::Point)
        new(S, P1, P2)
    end
    function AABB(shape::AbstractShape)
        S = Vector{AbstractShape}(undef, 1)
        S[1] = shape
        P1, P2 = boxed(shape)
        return AABB(S, P1, P2)
    end
end

"""
    intersected(axisbox::AABB, ray::Ray)

Check if a ray intersects an axis-aligned bounding box (AABB).
# Arguments
- `axisbox::AABB`: the axis-aligned bounding box to be checked for intersection.
- `ray::Ray`: the ray to be checked for intersection with the AABB.
# Returns
- `Bool`: `true` if the ray intersects the AABB, `false` otherwise.
"""
function intersected(axisbox::AABB, ray::Ray)::Bool
    # by having a specialized function we avoid useless allocations or operations (inverse...)
    p1 = axisbox.P1
    p2 = axisbox.P2
    O = ray.origin
    d = ray.dir

    t1x = (p1.x - O.x) / d.x
    t2x = (p2.x - O.x) / d.x
    t1y = (p1.y - O.y) / d.y
    t2y = (p2.y - O.y) / d.y
    t1z = (p1.z - O.z) / d.z
    t2z = (p2.z - O.z) / d.z

    # more concise version but i dont really trust it
    tmin = max(min(t1x, t2x), min(t1y, t2y), min(t1z, t2z))
    tmax = min(max(t1x, t2x), max(t1y, t2y), max(t1z, t2z))
    if tmax < max(ray.tmin, tmin)
        return false
    end
    first_hit = tmin > ray.tmin ? tmin : tmax
    first_hit > ray.tmax && return false
    return true

end

"""
    ray_intersection(axisbox::AABB, ray::Ray)

Calculate the intersection of a ray and an axis-aligned bounding box (AABB).
# Arguments
- `axisbox::AABB`: the axis-aligned bounding box to be intersected.
- `ray::Ray`: the ray intersecting the AABB.
# Returns
- `HitRecord`: The hit record of the first shape hit, if any.
- `nothing`: If no intersections occur.
# Notes
- This function checks if the ray intersects the AABB and, if so, finds the closest intersection point among the shapes contained within the AABB.
"""
function ray_intersection(axisbox::AABB, ray::Ray)
    if !intersected(axisbox, ray)
        return nothing
    else
        dim = length(axisbox.S)
        closest = nothing
        for i in 1:dim
            inter = ray_intersection(axisbox.S[i], ray)
            if isnothing(inter)
                continue
            end
            if (isnothing(closest) || inter.t < closest.t)
                closest = inter
            end
        end
        return closest
    end
end

"""
    boxed(axisbox::AABB)

Returns the two points defining the axis-aligned bounding box (AABB) `axisbox`.
# Arguments
- `axisbox::AABB`: the axis-aligned bounding box to be boxed.
# Returns
- `Tuple{Point, Point}`: a tuple containing the two points defining the AABB, where the first point is the minimum corner and the second point is the maximum corner.
"""
function boxed(axisbox::AABB)::Tuple{Point,Point}
    return (axisbox.P1, axisbox.P2)
end

"""
    quick_ray_intersection(S::AABB, ray::Ray)::Bool
Checks if a ray intersects with the Axis-Aligned Bounding Box without calculating the exact intersection point.
# Arguments
- `S::AABB`: The Axis-Aligned Bounding Box to check for intersection.
- `ray::Ray`: The ray to check for intersection with the Axis-Aligned Bounding Box.
# Returns
- `Bool`: `true` if the ray intersects with the Axis-Aligned Bounding Box, `false` otherwise.
"""
function quick_ray_intersection(S::AABB, ray::Ray)::Bool
    if !intersected(S, ray)
        return false
    else
        for shape in S.S
            if quick_ray_intersection(shape, ray)
                return true
            end
        end
        return false
    end
end