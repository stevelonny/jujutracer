# Redefine +,-,* and ≈ for Color types
# ColorTypes.RGB{T} should be equivalent to RGB
Base.:*(c::ColorTypes.RGB{T}, scalar::Real) where {T} = ColorTypes.RGB{T}(c.r * scalar, c.g * scalar, c.b * scalar)
Base.:*(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T} = ColorTypes.RGB{T}(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)
Base.:/(c::ColorTypes.RGB{T}, scalar::Real) where {T} = ColorTypes.RGB{T}(c.r / scalar, c.g / scalar, c.b / scalar)
Base.:/(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T} = ColorTypes.RGB{T}(c1.r / c2.r, c1.g / c2.g, c1.b / c2.b)
Base.:+(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T} = ColorTypes.RGB{T}(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)
Base.:-(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T} = ColorTypes.RGB{T}(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)
Base.:≈(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T} = c1.r ≈ c2.r && c1.g ≈ c2.g && c1.b ≈ c2.b

function is_close(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T}
    return c1.r ≈ c2.r && c1.g ≈ c2.g && c1.b ≈ c2.b
end

