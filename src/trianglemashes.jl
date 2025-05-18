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
"""
function Mat(a::Vec, b::Vec, c::Vec)
    return [a.x b.x c.x; a.y b.y c.y; a.z b.z c.z]
end

"""
"""
function Cramer(Mat::Matrix)
    det = Mat[1,1] * Mat[2,2] * Mat[3,3]
    det += Mat[1,2] * Mat[2,3] * Mat[3,1]
    det += Mat[1,3] * Mat[2,1] * Mat[3,2]
    det -= Mat[1,1] * Mat[2,3] * Mat[3,2]
    det -= Mat[1,2] * Mat[2,1] * Mat[3,3]
    det -= Mat[1,3] * Mat[2,2] * Mat[3,1]
    return det
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
    detM = Cramer(Mat(B, C, -d))

    if detM != 0.0
        # Cramer's rule for β, γ and t
        β = Cramer(Mat(O, C, -d)) / detM
        γ = Cramer(Mat(B, O, -d)) / detM
        t = Cramer(Mat(B, C, O)) / detM

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
