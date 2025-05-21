#----------------------------------------------------
#ImageTracer 
#----------------------------------------------------

"""
    struct ImageTracer

Convenient struct to hold the hdrimage and the camera.

# Fields
- `img::hdrimg`: The HDR image to be traced.
- `camera::AbstractCamera`: The camera used for tracing rays. Can be either `Orthogonal` or `Perspective`.

# Constructor
- `ImageTracer()`: Creates a new `ImageTracer` with a default HDR image and an orthogonal camera.
- `ImageTracer(img::hdrimg, camera::AbstractCamera)`: Creates a new `ImageTracer` with the specified HDR image and camera.
"""
struct ImageTracer
    img::hdrimg
    camera::AbstractCamera
    function ImageTracer(img::hdrimg, camera::AbstractCamera)
        new(img, camera)
    end
end

"""
    (it::ImageTracer)(col::Int, row::Int; u_pixel::Float64 = 0.5, v_pixel::Float64 = 0.5)

Return the ray cast from the camera through the pixel at (col, row) in the image.

# Arguments
- `col_pixel::Int`, `row_pixel::Int`: The column and row indexes of the pixel in the image.
- `u_pixel::Float64`, `v_pixel::Float64`: The pixel offset in the u and v directions (default is 0.5, center of the pixel).
"""
function (it::ImageTracer)(col_pixel::Int, row_pixel::Int; u_pixel::Float64=0.5, v_pixel::Float64=0.5)
    u = (col_pixel + u_pixel) / (it.img.w)
    v = 1 - (row_pixel + v_pixel) / (it.img.h)

    return it.camera(u, v)
end

"""
    (it::ImageTracer)(fun::Function)

Apply a function to each pixel in the image. Leverage parallel processing for performance.

# Arguments
- `fun::Function`: Must be a function that takes a `::Ray` as input and returns a color (`ColorTypes.RGB`).
"""
function (it::ImageTracer)(fun::Function)
    # remember: julia is column-major order
    @threads for i in eachindex(IndexCartesian(), it.img.img)
        col_pixel = i[2] - 1
        row_pixel = i[1] - 1
        ray = it(col_pixel, row_pixel)
        color = fun(ray)
        # we could remove boundary checks with @inbounds
        it.img[col_pixel, row_pixel] = color
    end
end
