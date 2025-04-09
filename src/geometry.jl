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

    """
        Vec(x::Float64, y::Float64, z::Float64)
    
    Create a new vector Vec with given dimensions.
    # Arguments
    - `x::Int`, `y::Int`, `z::Int`: vector dimensions.
    # Returns
    - `Vec`: A new vector.
    """
    function Vec(x::Float64, y::Float64, z::Float64)
        new(x, y, z)
    end
end