#-------------------------------------------------------------
# hdrimg
#-------------------------------------------------------------
"""
    hdrimg(w::Int, h::Int)

A struct representing a high dynamic range image (HDR image).

# Fields
- `img::Matrix{RGB}`: A matrix of RGB values representing the HDR image.
- `w::Int64`: The width of the image in pixels.
- `h::Int64`: The height of the image in pixels.
"""
struct hdrimg
    w::Int64
    h::Int64
    img::Matrix{RGB}

    """
        hdrimg(w::Int, h::Int)
    
    Create a new HDR image with the specified width and height.
    # Arguments
    - `w::Int`, `h::Int`: Width and height of the HDR image.
    # Returns
    - `hdrimg`: A new HDR image with the specified dimensions.
    """
    function hdrimg(w::Int, h::Int)
        img = Matrix{RGB}(undef, h, w)
        new(w, h, img)
    end
end

# Access method for hdrimg
Base.getindex(img::hdrimg, x::Int, y::Int) = img.img[y + 1, x + 1]
Base.setindex!(img::hdrimg, value::RGB, x::Int, y::Int) = (img.img[y + 1, x + 1] = value)

#function valid_coordinates(img::hdrimg, x, y)
#    return x >= 0 && x < img.w && y >= 0 && y < img.h
#end

#-------------------------------------------------------------
# Tone mapping 
#-------------------------------------------------------------
""" 
    _average_luminosity(img::hdrimg; type = "LF", delta = 0.0001)

Return the average luminosity of an HDR image, given the type of luminosity calculation to be used and delta to avoid.

# Arguments
- `img::hdrimg`: The HDR image for which to calculate the average luminosity.
- `type::String`: The type of luminosity calculation to be used. Options are:
    - `LF`: Luminosity function (default)
    - `M`: Mean luminosity
    - `W`: Weighted luminosity
    - `D`: Euclidean distance luminosity
- `delta::Float64`: A small value to avoid log(0) for black pixels (default is 0.0001).

# Returns
- `Float64`: The average luminosity of the HDR image.

"""
function _average_luminosity(img::hdrimg; type = "LF", delta = 0.0001)
    d = try
        delta >= 0 ? delta : throw(ArgumentError("Expected a positive delta value"))
    catch
        throw(ArgumentError("Invalid delta value"))
    end

    sum = 0.0
    for i in 1:img.h
        for j in 1:img.w
            sum += log10(_RGBluminosity(img.img[i, j], type) + d) #delta is useful to avoid log(0)
        end
    end
    return 10^(sum / (img.h * img.w))
end

# we developed tone mapping functions which modify the input hdrimg, so a return img is not really necessary. how do we want to handle this?
"""
    _normalize_img!(img::hdrimg: a::T, std::T) where {T<:Real, N}

Normalize an image by using
```math
R_i → R_i × \\frac{R_i}{⟨l⟩}
```

# Arguments
- `img::hdrimg`: The HDR image to be normalized.
- `a::T`: A positive value to be used in the normalization formula.
- `lum::T`: The average luminosity of the image. If not provided, it will be calculated using `_average_luminosity`.

# Raises
- `ArgumentError`: If `a` is not a positive number or if `lum` is not a number.
"""
function _normalize_img!(img::hdrimg; a=0.18 , lum = nothing)
    lum = something(lum, _average_luminosity(img)) # If luminosity is not provided, calculate it
    if !(lum isa Number)
        throw(ArgumentError("Luminosity must be a number"))
    end

    a= a>0 ? a : throw(ArgumentError("Expected a positive value for a"))

    img.img .= map(x ->  x* (a / lum), img.img)
end

"""
    _clamp_img!(hdr::hdrimg)

Clamp the HDR image values to the range [0, 1] using the formula:
```math
R_i → \\frac{R_i}{1+R_i}
```

# Arguments
- `hdr::hdrimg`: The HDR image to be clamped.
"""
function _clamp_img!(hdr::hdrimg)
    hdr.img .= map(x -> RGB(x.r/(1+x.r), x.g/(1+x.g), x.b/(1+x.b)), hdr.img)
end

"""
    _γ_correction!(hdr::hdrimg; γ = 1.0)

Apply gamma correction to the HDR image using the formula: 
```math
R_i → {R_i}^{1/γ}
```

# Arguments
- `hdr::hdrimg`: The HDR image to be gamma corrected.
- `γ::Float64`: The gamma value to be used for correction. Must be a positive number (default is 1.0).

# Raises
- `ArgumentError`: If `γ` is not a positive number.
"""
function _γ_correction!(hdr::hdrimg; γ = 1.0)
    if !(γ isa Number) || γ <= 0
        throw(ArgumentError("Gamma must be a positive number"))
    end
    hdr.img .= map(x -> RGB(x.r^(1.0/γ), x.g^(1.0/γ), x.b^(1.0/γ)), hdr.img)
end

"""
    tone_mapping(img::hdrimg; a=0.18, lum = nothing, γ = 1.0)

Apply tone mapping to the HDR image.

# Arguments
- `img::hdrimg`: The HDR image to be tone-mapped.
- `a::Float64`: A positive value to be used in the normalization formula (default is 0.18).
- `lum::Float64`: The average luminosity of the image. If not provided, it will be calculated using `_average_luminosity`.
- `γ::Float64`: The gamma value to be used for correction. Must be a positive number (default is 1.0).

# Returns
- `hdrimg`: The tone-mapped HDR image.

"""
function tone_mapping(img::hdrimg; a=0.18, lum = nothing, γ = 1.0)
    copy = img  

    # Normalize the image
    _normalize_img!(copy; a, lum)

    # Clamp the image
    _clamp_img!(copy)

    # Apply gamma correction
    _γ_correction!(copy; γ)

    return copy
end
