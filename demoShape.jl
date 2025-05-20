using Pkg
Pkg.activate(".")

using jujutracer

function demo3()
    if length(ARGS) != 4
        println("Usage: julia demo.jl <output_file> <width> <height> <cam_angle>")
        return
    end

    png_output = ARGS[1]*".png"
    width = parse(Int64,ARGS[2])
    height = parse(Int64,ARGS[3])
    cam_angle = parse(Float64,ARGS[4])
    pfm_output = ARGS[1]*".pfm"

    Sc = Scaling(1.0 / 1.5, 1.0 / 1.5, 1.0 / 1.5)
    green = RGB(0.0, 1.0, 0.0)
    red = RGB(1.0, 0.0, 0.0)
    blue = RGB(0.0, 0.0, 1.0)
    yellow = RGB(1.0, 1.0, 0.0)
    cyan = RGB(0.0, 1.0, 1.0)
    magenta = RGB(1.0, 0.0, 1.0)
    gray = RGB(0.5, 0.5, 0.5)
    Mat1 = Material(CheckeredPigment(32, 32, green, red), DiffusiveBRDF(UniformPigment(gray), 0.5))
    Mat2 = Material(CheckeredPigment(32, 32, blue, yellow), DiffusiveBRDF(UniformPigment(gray), 0.5))
    Mat3 = Material(CheckeredPigment(32, 32, cyan, magenta), DiffusiveBRDF(UniformPigment(gray), 0.5))
    S = Vector{AbstractShape}(undef, 2)
    
    S[1] = Triangle(Point(0.0, 0.5, 0.0), Point(0.0, -0.5, 0.0), Point(0.0, 0.0, 0.7), Mat1)
    S[2] = Box(Translation(0.0, 1.0, 0.0), Point(-0.5, -0.5, -0.5), Point(0.5, 0.5, 1.0), Mat2) - Sphere(Translation(0.0, 1.0, 0.0), Mat3)


    R_cam = Rz(cam_angle)
    world = World(S)
    #cam = Orthogonal(t = R_cam ⊙ Translation(-1.0, 0.0, 0.0), a_ratio = convert(Float64, 16 // 9))
    cam = Perspective(d = 2.0, t = R_cam ⊙ Translation(-2.5, 0.0, 1.0))
    hdr = hdrimg(width, height)
    ImgTr = ImageTracer(hdr, cam)

    flat = Flat(world)

    ImgTr(flat)

    println("Saving image in ", png_output)
    toned_img = tone_mapping(hdr; a = 0.5, lum = 0.5, γ = 1.3)
    # Save the LDR image
    save_ldrimage(get_matrix(toned_img), png_output)
    println("Saved image in ", png_output)
    println("Saving image in ", pfm_output)
    buf = IOBuffer()
    write_pfm_image(hdr, buf)
    # Write the buffer to a file
    seekstart(buf) # Reset the buffer position to the beginning
    # Open the file in write mode and save the buffer content
    write(pfm_output, buf)
    println("Done")
end

demo3()