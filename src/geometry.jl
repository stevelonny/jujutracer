import Base: *, +, -

#--------------------------------------------------------------------------
# Point type implementation
#--------------------------------------------------------------------------
"""
    Point(x::Float64, y::Float64, z::Float64)

Struct representing a point in 3D space.
# Fields
- `x::Float64`,`y::Float64`,`z::Float64`: Coordinates.
"""
struct Point
    x::Float64
    y::Float64
    z::Float64
end

#--------------------------------------------------------------------------
# Vec type implementation
#--------------------------------------------------------------------------
"""
    Vec(x::Float64, y::Float64, z::Float64)

A struct representing a vector in 3D space.
# Fields
- `x::Float64`,`y::Float64`,`z::Float64`: Coordinates.
# Methods
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
# Methods
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
    new(n.x, n.y, n.z)
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
# throws
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
Base.:*(v::T, scalar::Real) where {T<:Union{Vec, Normal}} = T(v.x * scalar, v.y * scalar, v.z * scalar)
Base.:*(scalar::Real, v::T) where {T<:Union{Vec, Normal}} = T(v.x * scalar, v.y * scalar, v.z * scalar) 
Base.:/(v::T, scalar::Real) where {T<:Union{Vec, Normal}} = T(v.x / scalar, v.y / scalar, v.z / scalar)
Base.:≈(v1::T, v2::T) where {T<:Union{Point, Vec, Normal}} = v1.x ≈ v2.x && v1.y ≈ v2.y && v1.z ≈ v2.z

"""
    a \\cdot b
    
Return scalara product (`\\cdot`) between Vec or Normal
"""
function ⋅(a::Union{Vec, Normal}, b::Union{Vec, Normal})
    return a.x * b.x + a.y * b.y + a.z * b.z
end

"""
    a \\times b
    
Return wedge product (`\\times`) between Vec or Normal as a Vec
"""
function ×(a::Union{Vec, Normal}, b::Union{Vec, Normal})
    return Vec(a.y * b.z - a.z * b.y, a.z*b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

#--------------------------------------------------------------------------
# Transformations
#--------------------------------------------------------------------------
abstract type AbstractTransformation end
"""
    Transformation
Generic concrete type Transformation
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
    function Transformation(M::Matrix, inv::Matrix)
        new(M, inv)
    end
end

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

struct Scaling <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Scaling(x::T,y::T,z::T) where{T<:Float64}
        # creating M and inv cloumn by column
        M=[[x, 0.0, 0.0, 0.0] [0.0, y, 0.0, 0.0] [0.0, 0.0, z, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1/x, 0.0, 0.0, 0.0] [0.0, 1/y, 0.0, 0.0] [0.0, 0.0, 1/z, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

struct Rx <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Rx(angle)
        # creating M and inv cloumn by column
        app = convert(Float64, angle)
        M=[[1.0, 0.0, 0.0, 0.0] [0.0, cos(app), sin(app), 0.0] [0.0, -sin(app), cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1.0, 0.0, 0.0, 0.0] [0.0, cos(app), -sin(app), 0.0] [0.0, sin(app), cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

struct Ry <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Ry(angle)
        # creating M and inv cloumn by column
        app = convert(Float64, angle)
        M=[[cos(app), 0.0, -sin(app), 0.0] [0.0, 1.0, 0.0, 0.0] [sin(app), 0.0, cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[cos(app), 0.0, sin(app), 0.0] [0.0, 1.0, 0.0, 0.0] [-sin(app), 0.0, cos(app), 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

struct Rz <: AbstractTransformation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Rz(angle)
        # creating M and inv cloumn by column
        app = convert(Float64, angle)
        M=[[cos(app), sin(app), 0.0, 0.0] [-sin(app), cos(app), 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[cos(app), -sin(app), 0.0, 0.0] [sin(app), cos(app), 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

#--------------------------------------------------------------------------
# Common methods
#--------------------------------------------------------------------------
"""
    \\odot(a, b)
Composition of two transformations, where `b` is the first acting on the object and `a` the second
"""
function ⊙(a, b)
    M::Matrix{Float64} = a.M * b.M
    inv::Matrix{Float64} = b.inv * a.inv
    return Transformation(M,inv)
end

"""
    inv(a::T)
Return the inverse transformation
"""
function inverse(a::AbstractTransformation)
    return Transformation(a.inv,a.M)
end

"""
    Transformation(v::Vec)
Applying the transformation to a Vec
"""
function (t::AbstractTransformation)(v::Vec)
    v4 = [v.x; v.y; v.z; 0]
    v4t = t.M * v4
    return Vec(v4t[1], v4t[2], v4t[3])
end

"""
    Transformation(p::Point)
Applying the transformation to a Point
"""
function (t::AbstractTransformation)(p::Point)
    v4 = [p.x; p.y; p.z; 1]
    v4t = t.M * v4
    return Point(v4t[1], v4t[2], v4t[3])
end

"""
    Transformation(n::Normal)
Applying the transformation to a Normal
"""
function (t::AbstractTransformation)(n::Normal)
    v4 = [n.x; n.y; n.z; 1]
    v4t = transpose(t.inv) * v4
    return Normal(v4t[1], v4t[2], v4t[3])
end

Base.:≈(a::Union{Transformation,Translation,Scaling,Rx,Ry,Rz},b::Union{Transformation,Translation,Scaling,Rx,Ry,Rz}) = a.M ≈ b.M && a.inv ≈ b.inv