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
