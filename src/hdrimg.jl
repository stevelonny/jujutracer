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

###### VERIFICARE CHE ESISTANO DEI CONTROLLI GIÀ IMPLEMENTATI PER MATRIX #######

# function get_pixel(self, x, y)
#     @assert self.valid_coordinates( x, y)
#     return self.img[x, y]
# end

# function set_pixel(self, pix::RGB, x, y)
#     @assert self.valid_coordinates( x, y)
#     self.img[x, y] = pix
# end

