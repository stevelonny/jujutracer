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
    function(A::Point, B::Point, C::Point)
        new(Transformation(), A, B, C, Material())
    end
    function(A::Point, B::Point, C::Point, Mat::Material)
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
    inv_ray = inverse(S.Tr)(ray)
    O = inv_ray.origin
    d = inv_ray.dir
    A = S.A
    B = S.B
    C = S.C
    # evaluating the determinant of the Matrix moltipling (β, γ, t)ᵗ
    detM = (B.x - A.x)*(C.y - A.y)*d.z + (C.x - A.x)*d.y*(B.z - A.z) + d.x*(B.y - A.y)*(C.z - A.z)
    detM -= (B.x - A.x)*(C.z - A.z)*d.y + (C.x - A.x)*d.z*(B.y - A.y) + d.x*(B.z - A.z)*(C.y - A.y)

    if detM != 0.0
        # Cramer's rule for β, γ and t
        β = (O.x - A.x)*(C.y - A.y)*d.z + (C.x - A.x)*d.y*(O.z - A.z) + d.x*(O.y - A.y)*(C.z - A.z) - (O.x - A.x)*(C.z - A.z)*d.y - (C.x - A.x)*d.z*(O.y - A.y) - d.x*(O.z - A.z)*(C.y - A.y)
        γ = (B.x - A.x)*(O.y - A.y)*d.z + (O.x - A.x)*d.y*(B.z - A.z) + d.x*(B.y - A.y)*(O.z - A.z) - (B.x - A.x)*(O.z - A.z)*d.y - (O.x - A.x)*d.z*(B.y - A.y) - d.x*(B.z - A.z)*(O.y - A.y)
        t = (B.x - A.x)*(C.y - A.y)*(O.z - A.z) + (C.x - A.x)*(O.y - A.y)*(B.z - A.z) + (O.x - A.x)*(B.y - A.y)*(C.z - A.z) - (B.x - A.x)*(C.z - A.z)*(O.y - A.y) - (C.x - A.x)*(O.z - A.z)*(B.y - A.y) - (O.x - A.x)*(B.z - A.z)*(C.y - A.y)

        β /= detM
        γ /= detM
        t /= detM
        if t > inv_ray.tmin && t < inv_ray.tmax && β <= 1.0 && β >= 0.0 && γ <= 1.0 && γ >= 0.0
            first_hit = t
        else
            return nothing
        end
    else
        return nothing
    end

    hit_point = inv_ray(first_hit)
    norm = Normal((B - A) × (C - A))
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
