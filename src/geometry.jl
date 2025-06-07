import Base: *, +, -

#--------------------------------------------------------------------------
# Point type implementation
#--------------------------------------------------------------------------
"""
    Point(x::Float64, y::Float64, z::Float64)

Struct representing a point in 3D space.
# Fields
- `x::Float64`,`y::Float64`,`z::Float64`: Coordinates.
# Constructors
- `Point(x::Float64, y::Float64, z::Float64)`: Create a Point from x, y, z coordinates.
- `Point(p::Vec)`: Create a Point from a Vec.
"""
struct Point
    x::Float64
    y::Float64
    z::Float64
    function Point(x, y, z)
        new(x, y, z)
    end
end

#--------------------------------------------------------------------------
# Vec type implementation
#--------------------------------------------------------------------------
"""
    Vec(x::Float64, y::Float64, z::Float64)

A struct representing a vector in 3D space.
# Fields
- `x::Float64`,`y::Float64`,`z::Float64`: Coordinates.
# Constructors
- `Vec(x::Float64, y::Float64, z::Float64)`: Create a Vec from x, y, z coordinates.
- `Vec(n::Normal)`: Create a Vec from a Normal.
- `Vec(p::Point)`: Create a Vec from a Point.
"""
struct Vec
    x::Float64
    y::Float64
    z::Float64
    function Vec(x, y, z)
        new(x, y, z)
    end
    function Vec(p::Point)
        new(p.x, p.y, p.z)
    end
end

#--------------------------------------------------------------------------
# Normal type implementation
#--------------------------------------------------------------------------
"""
    Normal(x::Float64, y::Float64, z::Float64)

Struct representing a unit vector (normal) in 3D space.
# Fields
- `x::Float64`,`y::Float64`,`z::Float64`: Coordinates.
# Constructors
- `Normal(v::Vec)`: Create a Normal from a Vec.
- `Normal(x::Float64, y::Float64, z::Float64)`: Create a Normal from x, y, z coordinates.
# Throws
- `ArgumentError`: If the vector is zero.
"""
struct Normal
    x::Float64
    y::Float64
    z::Float64
    function Normal(x, y, z)
        if x == 0 && y == 0 && z == 0
            throw(ArgumentError("Normal vector cannot be zero."))
        end
        m = sqrt(x^2 + y^2 + z^2)
        new(x/m, y/m, z/m)
    end
    function Normal(v::Vec)
        if v.x == 0 && v.y == 0 && v.z == 0
            throw(ArgumentError("Normal vector cannot be zero."))
        end
        m = sqrt(v.x^2 + v.y^2 + v.z^2)
        new(v.x/m, v.y/m, v.z/m)
    end
end

# Outside constructors
function Vec(n::Normal)
    return Vec(n.x, n.y, n.z)
end

function Point(p::Vec)
    return Point(p.x, p.y, p.z)
end

#--------------------------------------------------------------------------
# Common methods
#--------------------------------------------------------------------------
"""
    to_string(v::T) where {T<:Union{Point, Vec, Normal}}

Converts a Point, Vec, or Normal object to a string representation.
# Arguments
- `v::T`: The object to be converted. Expected to be a struct of 3 values (x, y, z).
# Returns
- A string representation of the object.
"""
function to_string(v::T) where {T<:Union{Point, Vec, Normal}}
    return "$(T)(x=$(v.x), y=$(v.y), z=$(v.z))"
end

"""
    squared_norm(v::Union{Vec, Normal})

Calculates the squared norm of a vector.
# Arguments
- `v::Union{Vec, Normal}`: The vector to be processed. Expected to be a struct of 3 values (x, y, z).
# Returns
- The squared norm of the vector.
"""
function squared_norm(v::Union{Vec, Normal})
    return v.x^2 + v.y^2 + v.z^2
end


"""
    norm(v::Union{Vec, Normal})

Calculates the norm of a vector.
# Arguments
- `v::Union{Vec, Normal}`: The vector to be processed. Expected to be a `Vec` or `Normal`  of 3 values (x, y, z).
# Returns
- The norm of the vector.
"""
function norm(v::Union{Vec, Normal})
    return sqrt(squared_norm(v))
end

"""
    normalize(v::Union{Vec, Normal})

Return a normalized vector.
# Arguments
- `v::Vec`: The vector to be normalized.
# Returns
- The normalized vector.
# Throws
- `ArgumentError`: If the vector is zero.
"""
function normalize(v::Union{Vec, Normal})
    if v.x == 0 && v.y == 0 && v.z == 0
        return v
    end
    return v/norm(v)
end



#--------------------------------------------------------------------------
# Operations
#--------------------------------------------------------------------------
Base.:+(a::T, b::Vec) where {T<:Union{Vec, Point}} = T(a.x + b.x, a.y + b.y, a.z + b.z)
Base.:+(a::Normal, b::Normal)= Normal(a.x + b.x, a.y + b.y, a.z + b.z)
Base.:-(a::T, b::Vec) where {T<:Union{Vec, Point}} = T(a.x - b.x, a.y - b.y, a.z - b.z)
Base.:-(a::Normal, b::Normal) = Normal(a.x - b.x, a.y - b.y, a.z - b.z)
Base.:-(v::T) where {T<:Union{Vec, Normal}} = T(-v.x, -v.y, -v.z)
Base.:-(a::Point,b::Point) = Vec(a.x-b.x, a.y-b.y, a.z-b.z)
Base.:*(a::Union{Vec, Normal}, b::Union{Vec, Normal}) = a.x * b.x + a.y * b.y + a.z * b.z
Base.:*(v::T, scalar::Real) where {T<:Union{Vec, Normal}} = Vec(v.x * scalar, v.y * scalar, v.z * scalar)
Base.:*(scalar::Real, v::T) where {T<:Union{Vec, Normal}} = Vec(v.x * scalar, v.y * scalar, v.z * scalar) 
Base.:/(v::T, scalar::Real) where {T<:Union{Vec, Normal}} = Vec(v.x / scalar, v.y / scalar, v.z / scalar)
Base.:≈(v1::T, v2::D) where {T<:Union{Vec, Normal}, D<:Union{Vec, Normal}} = v1.x ≈ v2.x && v1.y ≈ v2.y && v1.z ≈ v2.z
Base.:≈(v1::Point, v2::Point) = v1.x ≈ v2.x && v1.y ≈ v2.y && v1.z ≈ v2.z

"""
    a ⋅ b
    
Return scalar product (``\\cdot``) between `Vec` or `Normal`.
"""
function ⋅(a::Union{Vec, Normal}, b::Union{Vec, Normal})
    return a.x * b.x + a.y * b.y + a.z * b.z
end

"""
    a × b
    
Return wedge product (``\\times``) between `Vec` or `Normal` as a `Vec`.
"""
function ×(a::Union{Vec, Normal}, b::Union{Vec, Normal})
    return Vec(a.y * b.z - a.z * b.y, a.z*b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

#--------------------------------------------------------------------------
# Transformations
#--------------------------------------------------------------------------
"""
    struct Unsafe
A singleton struct used to indicate unsafe operations in transformations.
See also [`Transformation`](@ref) and [`_unsafe_inverse`](@ref).
"""
struct Unsafe end

"""
    AbstractTransformation

An abstract type that serves as a base for defining various geometric transformations.
Made concrete by [`Transformation`](@ref), [`Translation`](@ref), [`Scaling`](@ref), [`Rx`](@ref), [`Ry`](@ref), and [`Rz`](@ref).
"""
abstract type AbstractTransformation end


"""
    struct Transformation <: AbstractTransformation

Represents a transformation in 3D space with homogeneous coordinates.
This structure is a subtype of [`AbstractTransformation`](@ref).

# Fields
- `M::Matrix{Float64}`: The 4x4 transformation matrix.
- `inv::Matrix{Float64}`: The 4x4 inverse of the transformation matrix.

# Constructors
- `Transformation()`: Creates an identity transformation where `M` and `inv` are both 4x4 identity matrices.
- `Transformation(M::Matrix{Float64}, inv::Matrix{Float64})`: Creates a transformation with the given `M` and `inv` matrices.
- `Transformation(M::Matrix{Float64}, inv::Matrix{Float64}, unsafe::Unsafe)`: Creates a transformation with the given `M` and `inv` matrices, without veryfing the inputs.
Throws an `ArgumentError` if:
  - `M` or `inv` are not 4x4 matrices.
  - The last element of `M` or `inv` is not `1.0`.
  - `M` and `inv` are not inverses of each other.

# Notes
The `M` and `inv` matrices must satisfy the following conditions:
- Both must be 4x4 matrices.
- The last element of both matrices must be `1.0`.
- The product of `M` and `inv` must be _approximately_ equal to the 4x4 identity matrix.
"""
struct Transformation <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}
    function Transformation()
        # creating M and inv cloumn by column
        M=[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
    function Transformation(M::Matrix{Float64}, inv::Matrix{Float64})
        if size(M) != (4, 4) || size(inv) != (4, 4)
            throw(ArgumentError("M and inv must be 4x4 matrices."))
        end
        if M[4, 4] != 1.0 || inv[4, 4] != 1.0
            throw(ArgumentError("M and inv must be 4x4 matrices with the last element equal to 1."))
        end
        if !isapprox(M * inv, [[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]])
            throw(ArgumentError("M and inv must be inverses of each other."))
        end
        new(M, inv)
    end
    function Transformation(M::Matrix{Float64}, inv::Matrix{Float64}, unsafe::Unsafe)
        new(M, inv)
    end        
end

"""
    struct Translation <: AbstractTransformation

Represents a translation in 3D space with homogeneous coordinates.
This structure is a subtype of [`AbstractTransformation`](@ref).

# Fields
- `M::Matrix{Float64}`: The 4x4 transformation matrix.
- `inv::Matrix{Float64}`: The 4x4 inverse transformation matrix.

# Constructors
- `Translation(dx::Float64, dy::Float64, dz::Float64)`: 
  Creates a `Translation` object with translation offsets `dx`, `dy`, and `dz` along the x, y, and z axes, respectively.

- `Translation(v::Vec)`:
  Creates a `Translation` object using a `Vec` object.
"""
struct Translation <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Translation(dx::Float64, dy::Float64, dz::Float64)
        M = [1.0 0.0 0.0 dx; 0.0 1.0 0.0 dy; 0.0 0.0 1.0 dz; 0.0 0.0 0.0 1.0]
        Inv = [1.0 0.0 0.0 -dx; 0.0 1.0 0.0 -dy; 0.0 0.0 1.0 -dz; 0.0 0.0 0.0 1.0]
        new(M, Inv)
    end
    function Translation(v::Vec)
        M = [1.0 0.0 0.0 v.x; 0.0 1.0 0.0 v.y; 0.0 0.0 1.0 v.z; 0.0 0.0 0.0 1.0]
        Inv = [1.0 0.0 0.0 -v.x; 0.0 1.0 0.0 -v.y; 0.0 0.0 1.0 -v.z; 0.0 0.0 0.0 1.0]
        new(M, Inv)
    end
end

"""
    struct Scaling <: AbstractTransformation

Represents a scaling transformation in 3D space.
This structure is a subtype of [`AbstractTransformation`](@ref).

# Fields
- `M::Matrix{Float64}`: The 4x4 transformation matrix.
- `inv::Matrix{Float64}`: The 4x4 inverse of the transformation matrix.

# Constructor
- `Scaling(x::Float64, y::Float64, z::Float64):
    Creates a `Scaling` instance with scaling factors `x`, `y`, and `z` along the x, y, and z axes, respectively.
    Throws an `ArgumentError` if any of the scaling factors are zero.
"""
struct Scaling <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Scaling(x::Float64,y::Float64,z::Float64)
        # Check if the scaling factors are zero
        if x == 0.0 || y == 0.0 || z == 0.0
            throw(ArgumentError("Scaling factors cannot be zero."))
        end
        # creating M and inv cloumn by column
        M=[[x, 0.0, 0.0, 0.0] [0.0, y, 0.0, 0.0] [0.0, 0.0, z, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1/x, 0.0, 0.0, 0.0] [0.0, 1/y, 0.0, 0.0] [0.0, 0.0, 1/z, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

"""
    struct Rx <: AbstractTransformation

Represents a rotation transformation around the x-axis in 3D space.
This structure is a subtype of [`AbstractTransformation`](@ref).

# Fields
- `M::Matrix{Float64}`: The 4x4 transformation matrix.
- `inv::Matrix{Float64}`: The 4x4 inverse of the transformation matrix.

# Constructor
- `Rx(θ)`: Creates an `Rx` instance for a given rotation `θ` (in radians).

# See also
- [`Ry`](@ref): For rotation around the y-axis.
- [`Rz`](@ref): For rotation around the z-axis.
"""
struct Rx <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Rx(θ)
        # creating M and inv cloumn by column
        app = convert(Float64, θ)
        M=[[1.0, 0.0, 0.0, 0.0] [0.0, cos(app), sin(app), 0.0] [0.0, -sin(app), cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1.0, 0.0, 0.0, 0.0] [0.0, cos(app), -sin(app), 0.0] [0.0, sin(app), cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

"""
    struct Ry <: AbstractTransformation

Represents a rotation transformation around the y-axis in 3D space.
This structure is a subtype of [`AbstractTransformation`](@ref).

# Fields
- `M::Matrix{Float64}`: The 4x4 transformation matrix.
- `inv::Matrix{Float64}`: The 4x4 inverse of the transformation matrix.

# Constructor
- `Ry(θ)`: Creates an `Ry` instance for a given rotation `θ` (in radians).

# See also
- [`Rx`](@ref): For rotation around the x-axis.
- [`Rz`](@ref): For rotation around the z-axis.
"""
struct Ry <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Ry(θ)
        # creating M and inv cloumn by column
        app = convert(Float64, θ)
        M=[[cos(app), 0.0, -sin(app), 0.0] [0.0, 1.0, 0.0, 0.0] [sin(app), 0.0, cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[cos(app), 0.0, sin(app), 0.0] [0.0, 1.0, 0.0, 0.0] [-sin(app), 0.0, cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

"""
    struct Rz <: AbstractTransformation

Represents a rotation transformation around the z-axis in 3D space.
This structure is a subtype of [`AbstractTransformation`](@ref).

# Fields
- `M::Matrix{Float64}`: The 4x4 transformation matrix.
- `inv::Matrix{Float64}`: The 4x4 inverse of the transformation matrix.

# Constructor
- `Rz(θ)`: Creates an `Rz` instance for a given rotation `θ` (in radians).

# See also
- [`Rx`](@ref): For rotation around the x-axis.
- [`Ry`](@ref): For rotation around the y-axis.
"""
struct Rz <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Rz(θ)
        # creating M and inv cloumn by column
        app = convert(Float64, θ)
        M=[[cos(app), sin(app), 0.0, 0.0] [-sin(app), cos(app), 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[cos(app), -sin(app), 0.0, 0.0] [sin(app), cos(app), 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

#--------------------------------------------------------------------------
# Common methods for transformations
#--------------------------------------------------------------------------
"""
    ⊙(a, b)

Composition of two transformations, where `b` is the first acting on the object and `a` the second.
"""
function ⊙(a, b)
    M::Matrix{Float64} = a.M * b.M
    inv::Matrix{Float64} = b.inv * a.inv
    return Transformation(M,inv)
end

"""
    inverse(a::AbstractTransformation)

Return the inverse transformation.
"""
function inverse(a::AbstractTransformation)
    return Transformation(a.inv,a.M)
end

"""
    _unsafe_inverse(a::AbstractTransformation)

Return the inverse transformation without checking if the matrices are inverses of each other.
"""
function _unsafe_inverse(a::AbstractTransformation)
    return Transformation(a.inv,a.M, Unsafe())
end

"""
    (t::AbstractTransformation)(v::Vec)

Applies the transformation to a `Vec`.
"""
function (t::AbstractTransformation)(v::Vec)
    v4_x = t.M[1, 1] * v.x + t.M[1, 2] * v.y + t.M[1, 3] * v.z
    v4_y = t.M[2, 1] * v.x + t.M[2, 2] * v.y + t.M[2, 3] * v.z
    v4_z = t.M[3, 1] * v.x + t.M[3, 2] * v.y + t.M[3, 3] * v.z
    return Vec(v4_x, v4_y, v4_z)
end

"""
    (t::AbstractTransformation)(p::Point)

Applies the transformation to a `Point`.
"""
function (t::AbstractTransformation)(p::Point)
    v4t_x = t.M[1, 1] * p.x + t.M[1, 2] * p.y + t.M[1, 3] * p.z + t.M[1, 4]
    v4t_y = t.M[2, 1] * p.x + t.M[2, 2] * p.y + t.M[2, 3] * p.z + t.M[2, 4]
    v4t_z = t.M[3, 1] * p.x + t.M[3, 2] * p.y + t.M[3, 3] * p.z + t.M[3, 4]
return Point(v4t_x, v4t_y, v4t_z)
end

"""
    (t::AbstractTransformation)(n::Normal)

Applies the transformation to a `Normal`.
"""
function (t::AbstractTransformation)(n::Normal)
    # use the traspose!
    v4_x = t.inv[1, 1] * n.x + t.inv[2, 1] * n.y + t.inv[3, 1] * n.z
    v4_y = t.inv[1, 2] * n.x + t.inv[2, 2] * n.y + t.inv[3, 2] * n.z
    v4_z = t.inv[1, 3] * n.x + t.inv[2, 3] * n.y + t.inv[3, 3] * n.z
    return Normal(v4_x, v4_y, v4_z)
end

"""
    ≈(a::Union{Transformation, Translation, Scaling, Rx, Ry, Rz}, b::Union{Transformation, Translation, Scaling, Rx, Ry, Rz})

Defines an approximate equality operator `≈` for geometric transformations. 
Two transformations `a` and `b` are considered approximately equal if both their transformation matrices (`M`) and their inverses (`inv`) are approximately equal.
"""
Base.:≈(a::AbstractTransformation,b::AbstractTransformation) = a.M ≈ b.M && a.inv ≈ b.inv

#--------------------------------------------------------------------------
# ONB
#--------------------------------------------------------------------------
""" 
    create_onb_from_z(normal::Union{Vec, Normal})

Creates an orthonormal basis (ONB) from a given normal vector.
# Arguments
- `normal::Union{Vec, Normal}`: The NORMAL vector from which to create the ONB. It can be a `Vec` or `Normal`.
# Returns
- A tuple of three `Vec` objects representing the orthonormal basis vectors.
  - `e1`: The first basis vector.
  - `e2`: The second basis vector.
  - `normal`: The normal vector itself.
"""
function create_onb_from_z(normal::Union{Vec, Normal}) 
    sign = copysign(1.0, normal.z)
    a = -1.0 / (sign + normal.z)
    b = normal.x * normal.y * a

    e1= Vec(1.0 + sign * normal.x * normal.x * a, sign * b, -sign * normal.x)
    e2= Vec(b, sign + normal.y * normal.y * a, -normal.y)

    return e1, e2, normal
end