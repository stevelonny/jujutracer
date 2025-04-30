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
- `col::Int`, `row::Int`: The column and row indexes of the pixel in the image.
- `u_pixel::Float64`, `u_pixel::Float64`: The pixel offset in the u and v directions (default is 0.5, center of the pixel).
"""
function (it::ImageTracer)(col::Int, row::Int; u_pixel::Float64 = 0.5, v_pixel::Float64 = 0.5)
    # u = (col + u_pixel) / (it.img.w - 1)
    # v = (row + v_pixel) / (it.img.h - 1)
    u=( col -1 + u_pixel )/(it.img.w)
    v= 1+ (-row +1-v_pixel)/(it.img.h)

    return it.camera(u, v)
end

"""
    (it::ImageTracer)(fun::Function)

Apply a function to each pixel in the image.

# Arguments
- `fun::Function`: Must be a function that takes a `::Ray` as input and returns a color (`ColorTypes.RGB`).
"""
function (it::ImageTracer)(fun::Function)
    # Quick and dirty test to check if the function is a valid function
    # Should we check if the function takes a Ray? if yes, use methods(fun)
    #=result = fun(it.camera(0.5, 0.5))
    if !(isa(result, ColorTypes.RGB))
        throw(ArgumentError("The function must return a ColorTypes.RGB value."))
    end=#
    # remember: julia is column-major order
    for row in 1:it.img.h
        for col in 1:it.img.w
            ray = it(col, row)
            color = fun(ray)
            # we could remove boundary checks with @inbounds
            it.img.img[row, col] = color
        end
    end
end
