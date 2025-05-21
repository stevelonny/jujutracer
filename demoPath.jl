using Pkg
Pkg.activate(".")

using jujutracer

function demo4()
    if length(ARGS) != 4
        println("Usage: julia demoPath.jl <output_file> <width> <height> <cam_angle>")
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
    black = RGB(0.0, 0.0, 0.0)
    Mat1 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(32, 32, green, red), 0.5))
    Mat2 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(32, 32, blue, yellow), 0.5))
    Mat3 = Material(UniformPigment(black), SpecularBRDF(UniformPigment(red), 0.5))
    Mat4 = Material(UniformPigment(cyan), DiffusiveBRDF(UniformPigment(gray), 0.1))
    S = Vector{AbstractShape}(undef, 4)
    
    S[1] = Plane(Mat1)
    S[2] = Sphere(Mat2)
    S[3] = Sphere(Translation(0.0, 1.0, 0.0) ⊙ Sc, Mat3)
    S[4] = Plane(Translation(0.0, 0.0, 5.0), Mat4)


    R_cam = Rz(cam_angle)
    world = World(S)
    #cam = Orthogonal(t = R_cam ⊙ Translation(-1.0, 0.0, 0.0), a_ratio = convert(Float64, 16 // 9))
    cam = Perspective(d = 2.0, t = R_cam ⊙ Translation(-2.5, 0.0, 1.0))
    hdr = hdrimg(width, height)
    ImgTr = ImageTracer(hdr, cam)
    pcg = PCG()

    path = PathTracer(world, gray, pcg, 50, 5, 2)

    ImgTr(path)

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

demo4()