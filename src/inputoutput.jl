#-------------------------------------------------------------
# Save to LDR formats
#-------------------------------------------------------------

# we will support png and jpg formats
# steps to save a figure:
# 1. input an hdrimg
# 2. apply tone mapping
# 3. extract the matrix from the hdrimg
# 4. save the matrix to a file with fileio

function get_matrix(img::hdrimg)
    return img.img
end

function save_ldrimage(img_matrix::Matrix, filename::String)
    # Check if the file extension is valid
    if !(endswith(filename, ".png") || endswith(filename, ".jpg"))
        throw(ArgumentError("Invalid file extension. Only .png and .jpg are supported."))
    end
    # Check if the image is clamped
    if any(x -> x.r < 0 || x.g < 0 || x.b < 0, img_matrix)
        throw(ArgumentError("Image values are not clamped. Please clamp the image before saving."))
    end

    # Save the image using FileIO
    save(filename, img_matrix)

    # Return the path to the saved file
    return filename
end

#-------------------------------------------------------------
# PFM file - Read
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
# PFM file - Read
#-------------------------------------------------------------
"""
    write_pfm_image(img::hdrimg, io, endianness::Bool=true)

Write a PFM file encodiding the content of an `hdrimg`
"""
function write_pfm_image(img::hdrimg, io, endianness::Bool=true)
    endian_str = endianness ? "-1.0" : "1.0"
    header = string("PF\n", img.w, " ", img.h, "\n", endian_str, "\n")

    try
        write(io, header)
    catch e
        throw(InvalidPfmFileFormat("Invalid output file"))
    end

    for i in img.h:-1:1
        for j in 1:img.w
            color = img.img[i, j]
            _write_float(color.r, io, endianness)
            _write_float(color.g, io, endianness)
            _write_float(color.b, io, endianness)
        end
    end
end

function _write_float(f, io, endianness::Bool=true)
    data = reinterpret(UInt32, Float32(f))  # Assicura che sia Float32
    data = endianness ? data : ntoh(data)   # Converte se necessario
    write(io, data)
end