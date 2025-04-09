import Base: *, +, -
#--------------------------------------------------------------------------
# Vec type implementation
#--------------------------------------------------------------------------
"""
    Vec(x::Float64, y::Float64, z::Float64)

A struct representing a high dynamic range image (HDR image).

# Fields
- `x::Float64`: x coordinate
- `y::Float64`: y coordinate
- `z::Float64`: z coordinate
"""
struct Vec
    x::Float64
    y::Float64
    z::Float64
end



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
# Normal type implementation
#--------------------------------------------------------------------------
"""
    Normal(x::Float64, y::Float64, z::Float64)

Struct representing a normal vector in 3D space.
# Fields
- `x::Float64`,`y::Float64`,`z::Float64`: Coordinates.
"""
struct Normal
    x::Float64
    y::Float64
    z::Float64
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

Base.:*(v::T, scalar::Real) where {T<:Union{Vec, Normal}} = T(v.x * scalar, v.y * scalar, v.z * scalar) 
Base.:/(v::T, scalar::Real) where {T<:Union{Vec, Normal}} = T(v.x / scalar, v.y / scalar, v.z / scalar)
Base.:≈(v1::T, v2::T) where {T<:Union{Point, Vec, Normal}} = v1.x ≈ v2.x && v1.y ≈ v2.y && v1.z ≈ v2.z

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
- `v::Union{Vec, Normal}`: The vector to be processed. Expected to be a struct of 3 values (x, y, z).
# Returns
- The norm of the vector.
"""
function norm(v::Union{Vec, Normal})
    return sqrt(squared_norm(v))
end


function normalize(v::Union{Vec, Normal})
    n = norm(v)
    if n == 0
        return v
    else
        return Vec(v.x / n, v.y / n, v.z / n)
    end
end


#--------------------------------------------------------------------------
# Operations
#--------------------------------------------------------------------------
function Base.:+(a::T, b::Vec) where {T<:Union{Vec, Point}}
    try
        return T(a.x + b.x, a.y + b.y, a.z + b.z)
    catch
        throw(ArgumentError("Invalid geometric type"))
    end

end

function Base.:-(a::T, b::Vec) where {T<:Union{Vec, Point}}
    try
        return T(a.x - b.x, a.y - b.y, a.z - b.z)
    catch
        throw(ArgumentError("Invalid geometric type"))
    end

end

function Base.:*(a::Union{Vec, Normal}, b::Union{Vec, Normal})
    try
        return a.x * b.x + a.y * b.y + a.z * b.z
    catch
        throw(ArgumentError("Invalid geometric type"))
    end
end
