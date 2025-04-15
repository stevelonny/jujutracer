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
struct transformation
    M::Matrix{Float64}
    inv::Matrix{Float64}
    function transformation()
        # creating M and inv cloumn by column
        M=[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
    function transformation(M::Matrix, inv::Matrix)
        new(M, inv)
    end
end

struct traslation
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function traslation(v::Vec)
        # creating M and inv cloumn by column
        M = [[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [v.x, v.y, v.z, 1.0]]
        inv = [[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [-v.x, -v.y, -v.z, 1.0]]
        new(M,inv)
    end
end

struct scaling
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function scaling(x::T,y::T,z::T) where{T<:Float64}
        # creating M and inv cloumn by column
        M=[[x, 0.0, 0.0, 0.0] [0.0, y, 0.0, 0.0] [0.0, 0.0, z, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1/x, 0.0, 0.0, 0.0] [0.0, 1/y, 0.0, 0.0] [0.0, 0.0, 1/z, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

struct Rx
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Rx(angle::Float64)
        # creating M and inv cloumn by column
        M=[[1.0, 0.0, 0.0, 0.0] [0.0, cos(angle), sin(angle), 0.0] [0.0, -sin(angle), cos(angle), 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[1.0, 0.0, 0.0, 0.0] [0.0, cos(angle), -sin(angle), 0.0] [0.0, sin(angle), cos(angle), 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

struct Ry
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Ry(angle::Float64)
        # creating M and inv cloumn by column
        M=[[cos(angle), 0.0, -sin(angle), 0.0] [0.0, 1.0, 0.0, 0.0] [sin(angle), 0.0, cos(angle), 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[cos(angle), 0.0, sin(angle), 0.0] [0.0, 1.0, 0.0, 0.0] [-sin(angle), 0.0, cos(angle), 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

struct Rz
    M::Matrix{Float64}
    inv::Matrix{Float64}

    function Rz(angle::Float64)
        # creating M and inv cloumn by column
        M=[[cos(angle), sin(angle), 0.0, 0.0] [-sin(angle), cos(angle), 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        inv=[[cos(angle), -sin(angle), 0.0, 0.0] [sin(angle), cos(angle), 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
        new(M,inv)
    end
end

#--------------------------------------------------------------------------
# Common methods
#--------------------------------------------------------------------------

function ⊙(a ,b)
    M = Matrix{Float64}(undef,4,4)
    inv = Matrix{Float64}(undef,4,4)
    for i in 1:4
        for j in 1:4
            for k in 1:4
                M[i,j] += a.M[i,k] * b.M[k,j]
                inv[i,j] += b.inv[i,k] * a.inv[k,j]
            end
        end
    end
    return transformation(M,inv)
end

function inv(a::T) where {T<:Union{transformation,traslation,scaling,Rx,Ry,Rz}}
    return T(a.inv,a.M)
end

Base.:≈(a::Union{transformation,traslation,scaling,Rx,Ry,Rz},b::Union{transformation,traslation,scaling,Rx,Ry,Rz}) = a.M ≈ b.M && a.inv ≈ b.inv