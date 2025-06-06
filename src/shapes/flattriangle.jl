#---------------------------------------------------------
# General Methods
#---------------------------------------------------------

"""
    _sarrus(a::Vec, b::Vec, c::Vec)

Efficiently computes the determinant of the 3x3 matrix whose columns are `a`, `b`, and `c`, without allocating a matrix.
"""
function _sarrus(a::Vec, b::Vec, c::Vec)
    return a.x * b.y * c.z +
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
    function Triangle(Tr::AbstractTransformation, A::Point, B::Point, C::Point, Mat::Material)
        new(Tr, A, B, C, Mat)
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
        world_P=S.Tr(hit_point),
        normal=norm,
        surface_P=SurfacePoint(β, γ),
        t=first_hit,
        ray=ray,
        shape=S
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
function boxed(S::Triangle)::Tuple{Point,Point}
    A = S.Tr(S.A)
    B = S.Tr(S.B)
    C = S.Tr(S.C)
    P1 = Point(min(A.x, B.x, C.x), min(A.y, B.y, C.y), min(A.z, B.z, C.z))
    P2 = Point(max(A.x, B.x, C.x), max(A.y, B.y, C.y), max(A.z, B.z, C.z))
    return (P1, P2)
end