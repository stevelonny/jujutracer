using Pkg
Pkg.activate(".")

using jujutracer
using ArgParse
using Logging
using TerminalLoggers
using LoggingExtras

function parse_cli()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--width", "-W"
        arg_type = Int
        default = 640
        help = "Image width"
        "--height", "-H"
        arg_type = Int
        default = 360
        help = "Image height"
        "--output", "-o"
        default = "output.png"
        help = "Output image file"
        "--pfm_output", "-p"
        default = "output.pfm"
        help = "Output PFM file"
        "--renderer", "-r"
        dest_name = "renderer"
        arg_type = String
        range_tester = s -> s in ["path_tracer", "flat", "on_off", "point", "depth"]
        default = "path_tracer"
        help = "Renderer to use (path_tracer, flat, on_off or point)"
        "--antialiasing", "-a"
        arg_type = Int
        default = 2
        help = "Antialiasing level (default: 2)"
        "scene_file"
        help = "Scene file to parse"
        required = true
    end
    @add_arg_table! s begin
        "--n_rays"
        arg_type = Int
        default = 3
        help = "Number of rays per pixel (for path tracer)"
        "--depth"
        arg_type = Int
        default = 3
        help = "Ray depth (for path tracer and point)"
        "--russian"
        arg_type = Int
        default = 2
        help = "Russian roulette level (for path tracer)"
    end

    return parse_args(s)
end

function main()
    parsed_args = parse_cli()
    width = parsed_args["width"]
    height = parsed_args["height"]
    png_output = parsed_args["output"]
    pfm_output = parsed_args["pfm_output"]
    renderer = parsed_args["renderer"]
    antialiasing = parsed_args["antialiasing"]
    scene_file = parsed_args["scene_file"]
    n_rays = parsed_args["n_rays"]
    depth = parsed_args["depth"]
    russian = parsed_args["russian"]
    @info """
    Parsed arguments:
    - Width: $width
    - Height: $height
    - Output PNG: $png_output
    - Output PFM: $pfm_output
    - Renderer: $renderer
    - Antialiasing: $antialiasing
    - Scene file: $scene_file
    - Number of rays: $n_rays
    - Depth: $depth
    - Russian roulette: $russian
    """

    # Create a filtered logger
    module_filter(log) = log._module == jujutracer || log.level > Logging.Debug
    filtered_logger = EarlyFilteredLogger(module_filter, TerminalLogger(stderr, Logging.Debug))

    # Set as the global logger
    global_logger(filtered_logger)


    if !isfile(scene_file)
        throw(ArgumentError("Scene file does not exist: $scene_file"))
    end
    stream = open_InputStream(scene_file)
    scene = parse_scene(stream)

    world = scene.world
    camera = scene.camera

    gray = RGB(0.2, 0.2, 0.2)
    ambient = RGB(0.1, 0.1, 0.1)
    render = nothing
    pcg = PCG()

    if renderer == "flat"
        render = Flat(world)
    elseif renderer == "path_tracer"
        render = PathTracer(world, gray, pcg, n_rays, depth, russian)
    elseif renderer == "on_off"
        render = OnOff(world)
    elseif renderer == "point"
        render = PointLight(world, gray, ambient, depth)
    elseif renderer == "depth"
        render = DepthBVHRender(world; bvh_max_depth=scene.bvhdepth)
    else
        throw(ArgumentError("Invalid renderer type. Use 'path_tracer', 'flat', 'on_off', 'point' or 'depth'."))
    end

    hdr = hdrimg(width, height)
    imgtr = ImageTracer(hdr, camera)

    if antialiasing > 1
        imgtr(render, antialiasing, pcg)
    else
        imgtr(render)
    end

    toned_img = tone_mapping(hdr; a=0.5, γ=1.3)
    # Save the LDR image
    save_ldrimage(get_matrix(toned_img), png_output)
    write_pfm_image(hdr, pfm_output)
    println("Done")
end

main()