struct hdrimg
    w::Int64                #width
    h::Int64                #heigth
    img::zeros(RGB,h*w)     #array
end

function valid_coordinates(img::hdrimg, x, y)
    if x < img.w && x >= 0 && y < img.h && y >= 0 
        return true
    else
        return false
    end
end

function pixel_offset(img::hdrimg, x, y)
    y * img.w + x
end

function get_pixel(img::hdrimg, x, y)
    @assert valid_coordinates(img, x, y)
    return img.img[pixel_offset(img, x, y)]
end

function set_pixel(pix::RGB, x, y)
    @assert valid_coordinates(img, x, y)
    img.img[pixel_offset(img, x, y)] = pix
end