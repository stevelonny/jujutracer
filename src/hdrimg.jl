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
    return x >= 0 && x < img.w && y >= 0 && y < img.h
end

#-------------------------------------------------------------
# PFM file
#-------------------------------------------------------------#

# Exception for invalid PFM file format
struct InvalidPfmFileFormat <: Exception
    error_message::String
end

# Read a 32-bit floating-point number from 4 bytes, considering endianness
function _read_float(io::IO, is_little_endian::Bool)
    """4 bytes -> Float32, REQUIRES io from IO, is_little_endian Bool"""
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

# Decoding the type of endianness from a string
function _parse_endianness(endian::String)
    """Read endianness from a string, REQUIRES endian String, RETURN true if Little-endian, false if Big-endian"""
    # Try to convert the string to a float
    value = try 
        parse(Float64, endian)  # strip(endian) removes leading and trailing whitespaces
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

# Reading the image dimensions from a string 
function _parse_image_size(line::String)
    """Read image size from a string, REQUIRES line String, RETURN tuple of width and height"""
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




