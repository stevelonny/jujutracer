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
        world_P=S.Tr(hit_point),
        normal=norm,
        surface_P=SurfacePoint(β, γ),
        t=first_hit,
        ray=ray,
        shape=S
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
function boxed(S::Parallelogram)::Tuple{Point,Point}
    A = S.Tr(S.A)
    B = S.Tr(S.B)
    C = S.Tr(S.C)
    D = A + (B - A) + (C - A)  # D = A + AB + AC
    P1 = Point(min(A.x, B.x, C.x, D.x), min(A.y, B.y, C.y, D.y), min(A.z, B.z, C.z, D.z))
    P2 = Point(max(A.x, B.x, C.x, D.x), max(A.y, B.y, C.y, D.y), max(A.z, B.z, C.z, D.z))
    return (P1, P2)
end

"""
    quick_ray_intersection(S::Parallelogram, ray::Ray)::Bool
Checks if a ray intersects with the parallelogram without calculating the exact intersection point.
# Arguments
- `S::Parallelogram`: The parallelogram to check for intersection.
- `ray::Ray`: The ray to check for intersection with the parallelogram.
# Returns
- `Bool`: `true` if the ray intersects with the parallelogram, `false` otherwise.
"""
function quick_ray_intersection(S::Parallelogram, ray::Ray)::Bool
    inv_ray = _unsafe_inverse(S.Tr)(ray)
    O = inv_ray.origin - S.A
    d = inv_ray.dir

    detM = _sarrus(S.B - S.A, S.C - S.A, -d)

    if detM != 0.0
        β = _sarrus(O, S.C - S.A, -d) / detM
        γ = _sarrus(S.B - S.A, O, -d) / detM
        t = _sarrus(S.B - S.A, S.C - S.A, O) / detM

        return (t > inv_ray.tmin && t < inv_ray.tmax && β >= 0.0 && γ >= 0.0)
    else
        return false
    end
end