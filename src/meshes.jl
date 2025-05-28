#---------------------------------------------------------
# General Methods
#---------------------------------------------------------

"""
    _mat(a::Vec, b::Vec, c::Vec)

Returns a Matrix build with the transposed Vectors aᵗ, bᵗ and cᵗ.
"""
function _mat(a::Vec, b::Vec, c::Vec)
    return [a.x b.x c.x; a.y b.y c.y; a.z b.z c.z]
end

"""
    _sarrus(Mat::Matrix)

Implement the Sarrus method for calculation of the determinant of a 3x3 Matrix.
"""
function _sarrus(Mat::Matrix)
    det = Mat[1,1] * Mat[2,2] * Mat[3,3]
    det += Mat[1,2] * Mat[2,3] * Mat[3,1]
    det += Mat[1,3] * Mat[2,1] * Mat[3,2]
    det -= Mat[1,1] * Mat[2,3] * Mat[3,2]
    det -= Mat[1,2] * Mat[2,1] * Mat[3,3]
    det -= Mat[1,3] * Mat[2,2] * Mat[3,1]
    return det
end

"""
    _sarrus(a::Vec, b::Vec, c::Vec)

Efficiently computes the determinant of the 3x3 matrix whose columns are `a`, `b`, and `c`, without allocating a matrix.
"""
function _sarrus(a::Vec, b::Vec, c::Vec)
    return  a.x * b.y * c.z +
            a.y * b.z * c.x +
            a.z * b.x * c.y -
            a.z * b.y * c.x -
            a.y * b.x * c.z -
            a.x * b.z * c.y
end

#---------------------------------------------------------
# Triangle
#---------------------------------------------------------
"""
    struct Triangle <: AbstractShape

Triangle.
# Fields
- `t::Transformation`: the transformation applied to the triangle
- `A, B, C::Point`: the vertices of the triangle
- `Mat::Material`: the material of the shape

# Constructor
- `Triangle()`: creates a triangle with Identity `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a default material.
- `Triangle(Tr::AbstractTransformation)`: creates a triangle with `Tr` `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a default material.
- `Triangle(Mat::Material)`: creates a triangle with Identity `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a `Mat` material.
- `Triangle(Tr::AbstractTransformation, Mat::Material)`: creates a triangle with `Tr` `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a `Mat` material.
- `Triangle(A::Point, B::Point, C::Point)`: creates a triangle with Identity `Transformation` and vertices `A`, `B`, `C` and a default material.
- `Triangle(A::Point, B::Point, C::Point, Mat::Material)`: creates a triangle with Identity `Transformation` and vertices `A`, `B`, `C` and a `Mat` material.
"""
struct Triangle <: AbstractShape
    Tr::AbstractTransformation
    A::Point
    B::Point
    C::Point
    Mat::Material

    function Triangle()
        new(Transformation(), Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Material())
    end
    function Triangle(Tr::AbstractTransformation)
        new(Tr, Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Material())
    end
    function Triangle(Mat::Material)
        new(Transformation(), Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Mat)
    end
    function Triangle(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Mat)
    end
    function Triangle(A::Point, B::Point, C::Point)
        new(Transformation(), A, B, C, Material())
    end
    function Triangle(A::Point, B::Point, C::Point, Mat::Material)
        new(Transformation(), A, B, C, Mat)
    end
end

"""
    ray_intersection(S::Triangle, r::Ray)

Calculate the intersection of a ray and a triangle.
# Arguments
- `S::Triangle`: the triangle to be intersected.
- `ray::Ray`: the ray intersecting the triangle.
# Returns
- `HitRecord`: The hit record of the first shape hit, if any.
- `nothing`: If no intersections occur.

Differently from the other shapes, `ray_intersection(S::Triangle, ray::Ray)` incorporates `_triangle_normal` and `_point_to_uv`
"""
function ray_intersection(S::Triangle, ray::Ray)
    A = S.A                         # Point A
    B = S.B - A                     # Vec B - A
    C = S.C - A                     # Vec C - A
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = inv_ray.origin - A          # Vec O - A
    d = inv_ray.dir
    # M = (B C -d)
    # Mx = O
    # evaluating the determinant of the Matrix moltipling (β, γ, t)ᵗ
    detM = _sarrus(B, C, -d)

    if detM != 0.0
        # Cramer's rule for β, γ and t
        β = _sarrus(O, C, -d) / detM
        γ = _sarrus(B, O, -d) / detM
        t = _sarrus(B, C, O) / detM

        if t > inv_ray.tmin && t < inv_ray.tmax && β <= 1.0 && β >= 0.0 && γ <= 1.0 && γ >= 0.0 && β + γ <= 1.0
            first_hit = t
        else
            return nothing
        end
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = Normal(B × C)
    norm = (norm ⋅ d < 0.0) ? S.Tr(norm) : S.Tr(-norm)
    
    return HitRecord(
        world_P = S.Tr(hit_point),
        normal = norm,
        surface_P = SurfacePoint(β, γ),
        t = first_hit,
        ray = ray,
        shape = S
    )
end

"""
    boxed(S::Triangle)::Tuple{Point, Point}
Returns the two points defining the bounding box of the triangle `S`.
# Arguments
- `S::Triangle`: the triangle to be boxed.
# Returns
- `Tuple{Point, Point}`: a tuple containing the two points defining the bounding box of the triangle.
"""
function boxed(S::Triangle)::Tuple{Point, Point}
    A = S.Tr(S.A)
    B = S.Tr(S.B)
    C = S.Tr(S.C)
    P1 = Point(min(A.x, B.x, C.x), min(A.y, B.y, C.y), min(A.z, B.z, C.z))
    P2 = Point(max(A.x, B.x, C.x), max(A.y, B.y, C.y), max(A.z, B.z, C.z))
    return (P1, P2)
end
    

#---------------------------------------------------------
# Parallelogram
#---------------------------------------------------------
"""
    struct Parallelogram <: AbstractShape

Parallelogram

```
   C-----p
  /     /
 /     /
A-----B
```

# Fields
- `t::Transformation`: the transformation applied to the Parallelogram.
- `A, B, C::Point`: the vertices defining the quadrilateral's 
- `Mat::Material`: the material of the shape

# Constructor
- `Parallelogram()`: creates a parallelogram with Identity `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a default material.
- `Parallelogram(Tr::AbstractTransformation)`: creates a parallelogram with `Tr` `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a default material.
- `Parallelogram(Mat::Material)`: creates a parallelogram with Identity `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a `Mat` material.
- `Parallelogram(Tr::AbstractTransformation, Mat::Material)`: creates a parallelogram with `Tr` `Transformation` and vertices (0,0,0), (1,0,0), (0,1,0) and a `Mat` material.
- `Parallelogram(A::Point, B::Point, C::Point)`: creates a parallelogram with Identity `Transformation` and vertices `A`, `B`, `C` and a default material.
- `Parallelogram(A::Point, B::Point, C::Point, Mat::Material)`: creates a parallelogram with Identity `Transformation` and vertices `A`, `B`, `C` and a `Mat` material.
- `Parallelogram(A::Point, AB::Vec, AC::Vec)`: creates a parallelogram with Identity `Transformation` and vertices `A`, `A + AB`, `A + AC` and a default material.
"""
struct Parallelogram <: AbstractShape
    Tr::AbstractTransformation
    A::Point
    B::Point
    C::Point
    Mat::Material

    function Parallelogram()
        new(Transformation(), Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Material())
    end
    function Parallelogram(A::Point, AB::Vec, AC::Vec)
        new(Transformation(), A, A + AB, A + AC, Material())
    end
    function Parallelogram(Tr::AbstractTransformation)
        new(Tr, Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Material())
    end
    function Parallelogram(Mat::Material)
        new(Transformation(), Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Mat)
    end
    function Parallelogram(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Mat)
    end
    function Parallelogram(A::Point, B::Point, C::Point)
        new(Transformation(), A, B, C, Material())
    end
    function Parallelogram(A::Point, B::Point, C::Point, Mat::Material)
        new(Transformation(), A, B, C, Mat)
    end
end

"""
    ray_intersection(S::Parallelogram, r::Ray)

Calculate the intersection of a ray and a plane.
# Arguments
- `S::Parallelogram`: the parallelogram to be intersected.
- `ray::Ray`: the ray intersecting the triangle.
# Returns
- `HitRecord`: The hit record of the first shape hit, if any.
- `nothing`: If no intersections occur.

Differently from the other shapes, `ray_intersection(S::Parallelogram, ray::Ray)` incorporates `_parallelogram_normal` and `_point_to_uv`
"""
function ray_intersection(S::Parallelogram, ray::Ray)
    A = S.A                         # Point A
    B = S.B - A                     # Vec B - A
    C = S.C - A                     # Vec C - A
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = inv_ray.origin - A          # Vec O - A
    d = inv_ray.dir
    # M = (B C -d)
    # Mx = O
    # evaluating the determinant of the Matrix moltipling (β, γ, t)ᵗ
    detM = _sarrus(B, C, -d)

    if detM != 0.0
        # Cramer's rule for β, γ and t
        β = _sarrus(O, C, -d) / detM
        γ = _sarrus(B, O, -d) / detM
        t = _sarrus(B, C, O) / detM

        if t > inv_ray.tmin && t < inv_ray.tmax && β <= 1.0 && β >= 0.0 && γ <= 1.0 && γ >= 0.0
            first_hit = t
        else
            return nothing
        end
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = Normal(B × C)
    norm = (norm ⋅ d < 0.0) ? S.Tr(norm) : S.Tr(-norm)
    
    return HitRecord(
        world_P = S.Tr(hit_point),
        normal = norm,
        surface_P = SurfacePoint(β, γ),
        t = first_hit,
        ray = ray,
        shape = S
    )
end

"""
    boxed(S::Parallelogram)::Tuple{Point, Point}
Returns the two points defining the bounding box of the parallelogram.
# Arguments
- `S::Parallelogram`: the parallelogram to be boxed.
# Returns
- `Tuple{Point, Point}`: a tuple containing the two points defining the bounding box of the parallelogram.
"""
function boxed(S::Parallelogram)::Tuple{Point, Point}
    A = S.Tr(S.A)
    B = S.Tr(S.B)
    C = S.Tr(S.C)
    D = A + (B - A) + (C - A)  # D = A + AB + AC
    P1 = Point(min(A.x, B.x, C.x, D.x), min(A.y, B.y, C.y, D.y), min(A.z, B.z, C.z, D.z))
    P2 = Point(max(A.x, B.x, C.x, D.x), max(A.y, B.y, C.y, D.y), max(A.z, B.z, C.z, D.z))
    return (P1, P2)
end

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
function boxed(axisbox::AABB)::Tuple{Point, Point}
    return (axisbox.P1, axisbox.P2)
end
