#---------------------------------------------------------
# General Methods
#---------------------------------------------------------

"""
    Mat(a::Vec, b::Vec, c::Vec)

Returns a Matrix build with the transposed Vectors aᵗ, bᵗ and cᵗ
"""
function _mat(a::Vec, b::Vec, c::Vec)
    return [a.x b.x c.x; a.y b.y c.y; a.z b.z c.z]
end

"""
    Sarrus(Mat::Matrix)

Implement the Sarrus method for calculation of the determinant of a 3x3 Matrix
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

#---------------------------------------------------------
# Triangle
#---------------------------------------------------------
"""
    struct Triangle <: AbstractShape

Triangle
# Fields
- `t::Transformation`: the transformation applied to the triangle
- `A, B, C::Point`: the vertices of the triangle
- `Mat::Material`: the material of the shape

`Transofrmation` and `Point`s can't be assigned together. 
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

Calculate the intersection of a ray and a plane.
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
    inv_ray = inverse(S.Tr)(ray)
    O = inv_ray.origin - A          # Vec O - A
    d = inv_ray.dir
    # M = (B C -d)
    # Mx = O
    # evaluating the determinant of the Matrix moltipling (β, γ, t)ᵗ
    detM = _sarrus(_mat(B, C, -d))

    if detM != 0.0
        # Cramer's rule for β, γ and t
        β = _sarrus(_mat(O, C, -d)) / detM
        γ = _sarrus(_mat(B, O, -d)) / detM
        t = _sarrus(_mat(B, C, O)) / detM

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

#---------------------------------------------------------
# Quadrilateral
#---------------------------------------------------------
"""
    struct Quadrilateral <: AbstractShape

Quadrilateral
# Fields
- `t::Transformation`: the transformation applied to the triangle
- `A, B, C::Point`: the vertices of the triangle
- `Mat::Material`: the material of the shape

`Transofrmation` and `Point`s can't be assigned together. 
"""
struct Quadrilateral <: AbstractShape
    Tr::AbstractTransformation
    A::Point
    B::Point
    C::Point
    Mat::Material

    function Quadrilateral()
        new(Transformation(), Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Material())
    end
    function Quadrilateral(Tr::AbstractTransformation)
        new(Tr, Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Material())
    end
    function Quadrilateral(Mat::Material)
        new(Transformation(), Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Mat)
    end
    function Quadrilateral(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0), Mat)
    end
    function Quadrilateral(A::Point, B::Point, C::Point)
        new(Transformation(), A, B, C, Material())
    end
    function Quadrilateral(A::Point, B::Point, C::Point, Mat::Material)
        new(Transformation(), A, B, C, Mat)
    end
end

"""
    ray_intersection(S::Quadrilateral, r::Ray)

Calculate the intersection of a ray and a plane.
# Arguments
- `S::Quadrilateral`: the triangle to be intersected.
- `ray::Ray`: the ray intersecting the triangle.
# Returns
- `HitRecord`: The hit record of the first shape hit, if any.
- `nothing`: If no intersections occur.

Differently from the other shapes, `ray_intersection(S::Quadrilateral, ray::Ray)` incorporates `_triangle_normal` and `_point_to_uv`
"""
function ray_intersection(S::Quadrilateral, ray::Ray)
    A = S.A                         # Point A
    B = S.B - A                     # Vec B - A
    C = S.C - A                     # Vec C - A
    inv_ray = inverse(S.Tr)(ray)
    O = inv_ray.origin - A          # Vec O - A
    d = inv_ray.dir
    # M = (B C -d)
    # Mx = O
    # evaluating the determinant of the Matrix moltipling (β, γ, t)ᵗ
    detM = _sarrus(_mat(B, C, -d))

    if detM != 0.0
        # Cramer's rule for β, γ and t
        β = _sarrus(_mat(O, C, -d)) / detM
        γ = _sarrus(_mat(B, O, -d)) / detM
        t = _sarrus(_mat(B, C, O)) / detM

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

#---------------------------------------------------------
# AABB
#---------------------------------------------------------

struct AABB <: AbstractShape
    Tr::AbstractTransformation
    S::Vector{AbstractShape}
    P1::Point
    P2::Point

    function AABB(S::Vector{AbstractShape}, P1::Point, P2::Point)
        new(Transformation(), S, P1, P2)
    end
    function AABB(Tr::AbstractTransformation, S::Vector{AbstractShape}, P1::Point, P2::Point)
        new(Tr, S, P1, P2)
    end
    function AABB(box::Box, S::Vector{AbstractShape})
        new(box.Tr, S, box.P1, box.P2)
    end
end

function ray_intersection(box::AABB, ray::Ray)
    inv_ray = inverse(box.Tr)(ray)
    repo = ray_intersection(Box(box.P1, box.P2), inv_ray)

    if isnothing(repo)
        return nothing
    else
        dim = length(box.S)
        closest = nothing
        for i in 1:dim
            inter = ray_intersection(box.S[i], inv_ray)
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