# Redefine +,-,* and ≈ for Color types
# ColorTypes.RGB{T} should be equivalent to RGB
Base.:*(c::RGB, scalar::Real) = RGB(c.r * scalar, c.g * scalar, c.b * scalar)
Base.:*(c1::RGB, c2::RGB) = RGB(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)
Base.:/(c::RGB, scalar::Real) = RGB(c.r / scalar, c.g / scalar, c.b / scalar)
Base.:/(c1::RGB, c2::RGB) = RGB(c1.r / c2.r, c1.g / c2.g, c1.b / c2.b)
Base.:+(c1::RGB, c2::RGB) = RGB(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)
Base.:-(c1::RGB, c2::RGB) = RGB(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)
Base.:≈(c1::RGB, c2::RGB) = c1.r ≈ c2.r && c1.g ≈ c2.g && c1.b ≈ c2.b

function is_close(c1::ColorTypes.RGB{T}, c2::ColorTypes.RGB{T}) where {T}
    return c1.r ≈ c2.r && c1.g ≈ c2.g && c1.b ≈ c2.b
end

