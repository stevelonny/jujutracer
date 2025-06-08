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

# Functional Usage
- `ImageTracer(fun::Function)`: tracing the image with `fun` renderer.
- `ImageTracer(fun::Function, AA::Int64, pcg::PCG)`: tracing the image with `fun` renderer and Anti-Aliasing method with AA^2 subdivision in the pixel.
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
# Returns
- `Ray`: The ray cast from the camera through the specified pixel.
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
    total = length(it.img.img)
    progress = Threads.Atomic{Int}(0)
    update_interval = max(1, div(total, 500)) # update progress every 0.2% of total
    renderer_type = typeof(fun).name.name  # Get type name as Symbol
    @info "Starting image tracing." threads=(Threads.nthreads()) render=(renderer_type) w=(it.img.w) h=(it.img.h) aa=0
    if fun isa OnOff
        @debug "OnOff renderer parameters" bg_color = fun.background_color fg_color = fun.foreground_color
    elseif fun isa Flat
        @debug "Flat renderer parameters" bg_color = fun.background_color
    elseif fun isa PathTracer
        @debug "PathTracer parameters" bg_color = fun.background_color n_rays = fun.n_rays depth = fun.depth russian = fun.russian
    elseif fun isa PointLight
        @debug "PointLight parameters" bg_color = fun.background_color amb_color = fun.ambient_color point_depth = fun.max_depth
    end
    starting_time = time_ns()
    # remember: julia is column-major order
    @withprogress name = "Rendering" begin
        @threads for i in eachindex(IndexCartesian(), it.img.img)
            col_pixel = i[2] - 1
            row_pixel = i[1] - 1
            ray = it(col_pixel, row_pixel)
            color = fun(ray)
            # we could remove boundary checks with @inbounds
            it.img[col_pixel, row_pixel] = color
            count = Threads.atomic_add!(progress, 1)
            if count % update_interval == 0
                @logprogress count / total
            end
        end # forloop
    end # withprogress
    elapsed_time = (time_ns() - starting_time) / 1e9
    @info "Image tracing completed in $(elapsed_time) seconds."
end

"""
    (it::ImageTracer)(fun::Function, AA::Int64, pcg::PCG)

Apply a function to each pixel in the image with Anti-Aliasing (AA) leveraging stratified random sampling.

# Arguments
- `fun::Function`: Must be a function that takes a `::Ray` as input and returns a color (`ColorTypes.RGB`).
- `AA::Int64`: The Anti-Aliasing factor, which determines the number of samples per pixel (AA^2 samples).
- `pcg::PCG`: A pseudo-random number generator for generating random offsets in the pixel.
"""
function (it::ImageTracer)(fun::Function, AA::Int64, pcg::PCG)
    total = length(it.img.img)
    progress = Threads.Atomic{Int}(0)
    update_interval = max(1, div(total, 500)) # update progress every 0.2% of total
    renderer_type = typeof(fun).name.name  # Get type name as Symbol
    @info "Starting image tracing."  threads=(Threads.nthreads()) render=(renderer_type) w=(it.img.w) h=(it.img.h) aa=(AA)
    if fun isa OnOff
        @debug "OnOff renderer parameters" bg_color = fun.background_color fg_color = fun.foreground_color
    elseif fun isa Flat
        @debug "Flat renderer parameters" bg_color = fun.background_color
    elseif fun isa PathTracer
        @debug "PathTracer parameters" bg_color = fun.background_color n_rays = fun.n_rays depth = fun.depth russian = fun.russian
    elseif fun isa PointLight
        @debug "PointLight parameters" bg_color = fun.background_color amb_color = fun.ambient_color point_depth = fun.max_depth
    end
    starting_time = time_ns()
    @withprogress name = "Rendering" begin
        @threads for i in eachindex(IndexCartesian(), it.img.img)
            col_pixel = i[2] - 1
            row_pixel = i[1] - 1
            color = RGB(0.0, 0.0, 0.0)
            for idx in 1:(AA^2)
                j = div(idx - 1, AA) + 1
                k = mod(idx - 1, AA) + 1
                ray = it(col_pixel,
                    row_pixel,
                    u_pixel=(j - 1 + rand_uniform(pcg)) / AA,
                    v_pixel=(k - 1 + rand_uniform(pcg)) / AA)
                color += fun(ray)
            end
            it.img[col_pixel, row_pixel] = color / (AA^2)
            count = Threads.atomic_add!(progress, 1)
            if count % update_interval == 0
                @logprogress count / total
            end
        end # forloop
    end # withprogress
    elapsed_time = (time_ns() - starting_time) / 1e9
    @info "Image tracing completed in $(elapsed_time) seconds."
end