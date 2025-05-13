#-------------------------------------------------------------
# Save to LDR formats
#-------------------------------------------------------------

# we will support png and jpg formats
# steps to save a figure:
# 1. input an hdrimg
# 2. apply tone mapping
# 3. extract the matrix from the hdrimg
# 4. save the matrix to a file with fileio

"""
    get_matrix(img::hdrimg)

Extract the matrix from an HDR image.

# Arguments
- `img::hdrimg`: The HDR image from which to extract the matrix.
# Returns
- `Matrix`: The matrix representation of the HDR image.
"""
function get_matrix(img::hdrimg)
    return img.img
end

"""
    save_ldrimage(img_matrix::Matrix, filename::String)

Save an LDR image to a file.

# Arguments
- `img_matrix::Matrix`: The matrix representation of the image to be saved.
- `filename::String`: The name of the file to save the image to, including the file extension (".png" or ".jpg").
# Returns
- `String`: The path to the saved file.
# Raises
- `ArgumentError`: If the file extension is not valid or if the image values are not clamped.
"""
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
"""
    InvalidPfmFileFormat <: Exception

Exception raised when the PFM file format is invalid or cannot be read.

# Fields
- `error_message::String`: The error message describing the issue.
"""
struct InvalidPfmFileFormat <: Exception
    error_message::String
end

"""
    _read_float(io::IO, is_little_endian)

Read a Float32 value by interpreting 4 bytes with the correct endianness from a buffer.

# Arguments
- `io::IO`: The input stream from which to read the float.
- `is_little_endian::Bool`: A boolean indicating whether the float is in little-endian format.
# Returns
- `Float32`: The read float value.
# Raises
- `InvalidPfmFileFormat`: If there is an error reading the bytes from the file.
"""
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


"""
    _read_line(io::IO)

Read a line from the input buffer.
# Arguments
- `io::IO`: The input stream from which to read the line.
# Returns
- `String`: The read line.
"""
function _read_line(io)
    line::String = readline(io)
    return line
end


"""
    _parse_endianness(endian::String)

Parse endianness of the PFM file from a string.
# Arguments
- `endian::String`: The string representation of the endianness, expected to be "±1.0".
# Returns
- `Bool`: Returns true if the endianness is little-endian, false if big-endian.
# Raises
- `InvalidPfmFileFormat`: If the endianness value is invalid or missing.
"""
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


"""
    _parse_image_size(line::String)

Read image size from a string.
# Arguments
- `line::String`: The string representation of the image size, expected to be a couple of ints "width height".
# Returns
- `Tuple{Int, Int}`: A tuple containing the width and height of the image.
# Raises
- `InvalidPfmFileFormat`: If the image size specification is invalid or if the width/height values are not integers.
"""
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

"""
    read_pfm_image(io::IO)

Read a PFM image from an input stream.
# Arguments
- `io::IO`: The input stream from which to read the PFM image.
# Returns
- `hdrimg`: The HDR image read from the PFM file.
# Raises
- `InvalidPfmFileFormat`: If the PFM file format is invalid or if there are issues reading the file.
"""
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
    for row_pixel in (h-1):-1:0
        for col_pixel in 0:(w-1)
            r = _read_float(io, endianness)
            g = _read_float(io, endianness)
            b = _read_float(io, endianness)
            img[col_pixel, row_pixel] = RGB(r, g, b)
        end
    end

    return img
end

#-------------------------------------------------------------
# PFM file - Write
#-------------------------------------------------------------
"""
    write_pfm_image(img::hdrimg, io, endianness::Bool=true)

Write a PFM file encodiding the content of an `hdrimg`
# Arguments
- `img::hdrimg`: The HDR image to be written to the PFM file.
- `io::IO`: The output stream to which the PFM image will be written.
- `endianness::Bool`: A boolean indicating whether to write the float values in little-endian format (default is true).
"""
function write_pfm_image(img::hdrimg, io::IOBuffer, endianness::Bool=true)
    endian_str = endianness ? "-1.0" : "1.0"
    header = string("PF\n", img.w, " ", img.h, "\n", endian_str, "\n")

    try
        write(io, header)
    catch e
        throw(InvalidPfmFileFormat("Invalid output file"))
    end

    for row_pixel in (img.h-1):-1:0
        for col_pixel in 0:(img.w-1)
            color = img[col_pixel, row_pixel]
            _write_float!(color.r, io, endianness)
            _write_float!(color.g, io, endianness)
            _write_float!(color.b, io, endianness)
        end
        # println(row_pixel)
    end
end

function write_pfm_image(img::hdrimg, filename::String, endianness::Bool=true)
    # Check if the file extension is valid
    if !(endswith(filename, ".pfm"))
        throw(ArgumentError("Invalid file extension. Only .pfm is supported."))
    end

    # Open a temporary IOBuffer to write the PFM image
    io = IOBuffer()
    write_pfm_image(img, io, endianness)
    seekstart(io)  # Reset the buffer position to the beginning
    
    open(filename, "w") do file
        write(file, io)
    end
    close(io)  # Close the IOBuffer

end

"""
    _write_float!(f, io, endianness::Bool=true)

Write a Float32 value to the output stream with the correct endianness.
# Arguments
- `f`: The float value to be written.
- `io`: The output stream to which the float will be written.
- `endianness::Bool`: A boolean indicating whether to write the float in little-endian format (default is true).
"""
function _write_float!(f, io, endianness::Bool=true)
    data = reinterpret(UInt32, Float32(f))  # Assicura che sia Float32
    data = endianness ? data : ntoh(data)   # Converte se necessario
    write(io, data)
end