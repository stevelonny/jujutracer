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



function _lumi_mean(color)
    return (color.r + color.g + color.b) / 3
end

function _lumi_weighted(color)
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b # Weights from CCIR 601
end

function _lumi_D(color)
    return sqrt( color.r^2 + color.g^2 + color.b^2 )
end

function _lumi_Func(color)
    return (max(color.r, color.g, color.b) + min(color.r, color.g, color.b)) / 2
end

"""INPUT: 
    RGB color  
    type luminosity calculation:
        -  LF: Luminosity function (default),
        -  M: Mean luminosity,
        -  W: Weighted luminosity,
        -  D: Euclidean distance luminosity 
    RETURN luminosity value"""
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
