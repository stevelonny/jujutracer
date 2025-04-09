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