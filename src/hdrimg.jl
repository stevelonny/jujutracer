#-------------------------------------------------------------
# hdrimg
#-------------------------------------------------------------
"""hdrimg contains a width, height and a matrix of RGB values"""
struct hdrimg
    w::Int64
    h::Int64
    img::Matrix{RGB}

    function hdrimg(w::Int, h::Int)
        img = Matrix{RGB}(undef, h, w)
        new(w, h, img)
    end
end

function valid_coordinates(img::hdrimg, x, y)
    return x > 0 && x <= img.w && y > 0 && y <= img.h
end

#-------------------------------------------------------------
# PFM file
#-------------------------------------------------------------

# Exception for invalid PFM file format
struct InvalidPfmFileFormat <: Exception
    error_message::String
end

"""4 bytes -> Float32, INPUT io from IO, is_little_endian Bool """
function _read_float(io::IO, is_little_endian)

    bytes = try
        read(io, UInt32)
    catch e
        throw(InvalidPfmFileFormat("Impossible to read bytes from the file"))
    end

    if !is_little_endian 
        bytes = bswap(bytes)
    end

    return reinterpret(Float32, bytes)
end


"""Read a line from the file, INPUT stream"""
function _read_line(io)
    line::String = readline(io)
    return line
end


"""Read endianness from a string, INPUT endian String, RETURN true if Little-endian, false if Big-endian"""
function _parse_endianness(endian::String)
    value = try 
        Int(parse(Float64, endian)) 
    catch e
        throw(InvalidPfmFileFormat("Invalid or missing endianness specification"))
    end

    # return true if Little-endian, false if Big-endian
    if value > 0
        return false  # Big-endian
    elseif value < 0
        return true   # Little-endian
    else
        throw(InvalidPfmFileFormat("Endianness value cannot be 0. Expected a positive or negative value."))
    end
end


"""Read image size from a string, INPUT line String, RETURN tuple of width and height"""
function _parse_image_size(line::String)
    dims = split(line)
    if length(dims) != 2
        throw(InvalidPfmFileFormat("Invalid image size specification"))
    end

    w , h = try
        parse(Int, dims[1]), parse(Int, dims[2])
    catch e
        throw(InvalidPfmFileFormat("Invalid weight/hight"))
    end
    return w, h
end


function read_pfm_image(io)
    # Read the first line, should be "PF"
    line = _read_line(io)
    if line != "PF"
        throw(InvalidPfmFileFormat("Non-specified PF type"))
    end

    # Read the second line, should be "width height"
    line = _read_line(io)
    w, h = _parse_image_size(line)

    # Read the third line, should be "±1.0"
    line = _read_line(io)
    endianness = _parse_endianness(line)

    # Read the PFM image, from the bottom to the top, from left to right
    img = hdrimg(w, h)
    for i in h:-1:1
        for j in 1:w
            r = _read_float(io, endianness)
            g = _read_float(io, endianness)
            b = _read_float(io, endianness)
            img.img[i, j] = RGB(r, g, b)
        end
    end

    return img
end

#-------------------------------------------------------------
# Luminosity 
#-------------------------------------------------------------
""" INPUT: 
    hdrimg
    +type luminosity calculation:
        'LF' : Luminosity function (default),
        'M' : Mean luminosity,
        'W' : Weighted luminosity,
        'D' : Euclidean distance luminosity 
    +Delta (default 0.0001): useful to avoid log(0) for black pixels
    RETURN luminosity mean value"""
function average_luminosity(img::hdrimg; type = "LF", delta = 0.0001)
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


function normalize_img(img::hdrimg; a=0.18 , lum = nothing)
    lum = something(lum, average_luminosity(img)) # If luminosity is not provided, calculate it
    if !(lum isa Number)
        throw(ArgumentError("Luminosity must be a number"))
    end

    a= a>0 ? a : throw(ArgumentError("Expected a positive value for a"))

    for i in 1:img.h
        for j in 1:img.w
            img.img[i, j] = img.img[i, j] * (a / lum)
        end
    end

    return img
end




