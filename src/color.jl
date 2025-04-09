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


"""
    _lumi_mean(color)

Basic mean luminosity function.

# Arguments
- The RGB color to be processed. Expected to be a struct of 3 values (r, g, b).

# Returns
- The mean luminosity value of the pixel.
"""
function _lumi_mean(color)
    return (color.r + color.g + color.b) / 3
end

"""
    _lumi_weighted(color)

Weighted mean luminosity function according to CCIR 601.

# Arguments
- The RGB color to be processed. Expected to be a struct of 3 values (r, g, b).

# Returns
- The luminosity value of the pixel.
"""
function _lumi_weighted(color)
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b # Weights from CCIR 601
end

"""
    _lumi_D(color)

Euclidean distance luminosity function.

# Arguments
- The RGB color to be processed. Expected to be a struct of 3 values (r, g, b).

# Returns
- The luminosity value of the pixel.
"""
function _lumi_D(color)
    return sqrt( color.r^2 + color.g^2 + color.b^2 )
end

"""
    _lumi_Func(color)

Luminosity function according to the formula: ``\\frac{max(r,g,b) + min(r,g,b)}{2}``.

# Arguments
- The RGB color to be processed. Expected to be a struct of 3 values (r, g, b).

# Returns
- The luminosity value of the pixel.
"""
function _lumi_Func(color)
    return (max(color.r, color.g, color.b) + min(color.r, color.g, color.b)) / 2
end

"""
    _RGBluminosity(color, type = "LF")

Calculate the luminosity of a color using different methods.

# Arguments
- color: The RGB color to be processed. Expected to be a struct of 3 values (r, g, b).
- type: The type of luminosity calculation to perform. Options are:
    - 'LF' : Luminosity function (default),
    - 'M' : Mean luminosity,
    - 'W' : Weighted luminosity,
    - 'D' : Euclidean distance luminosity.

# Returns
- The luminosity value of the pixel.
"""
function _RGBluminosity(color, type = "LF")
    if type == "M"
        return _lumi_mean(color)
    elseif type == "W"
        return _lumi_weighted(color)
    elseif type == "D"
        return _lumi_D(color)
    elseif type == "LF"
        return _lumi_Func(color)
    else
        throw(ArgumentError("Invalid Luminosity type"))
    end
end
