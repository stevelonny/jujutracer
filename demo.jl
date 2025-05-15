using Pkg
Pkg.activate(".")

using jujutracer

function demo()
    if length(ARGS) != 4
        println("Usage: julia demo.jl <output_file> <width> <height> <cam_angle>")
        return
    end

    png_output = ARGS[1]*".png"
    width = parse(Int64,ARGS[2])
    height = parse(Int64,ARGS[3])
    cam_angle = parse(Float64,ARGS[4])
    pfm_output = ARGS[1]*".pfm"

    Sc = Scaling(1.0 / 10.0, 1.0 / 10.0, 1.0 / 10.0)
    
    color1 = RGB(0.7, 0.3, 1.0)
    color2 = RGB(0.9, 0.8, 0.7)
    colol3 = RGB(0.1, 0.2, 0.3)
    Mat1 = Material(UniformPigment(color1), DiffusiveBRDF(UniformPigment(color1), 0.5))
    Mat2 = Material(CheckeredPigment(4, 4, color1, color2), DiffusiveBRDF(UniformPigment(color1), 0.5))

    S = Vector{AbstractShape}(undef, 10)
    S[1] = Sphere(Translation(0.5, 0.5, 0.5) ⊙ Sc, Mat1)
    S[2] = Sphere(Translation(-0.5, 0.5, 0.5) ⊙ Sc, Mat1)
    S[3] = Sphere(Translation(0.5, -0.5, 0.5) ⊙ Sc, Mat1)
    S[4] = Sphere(Translation(0.5, 0.5, -0.5) ⊙ Sc, Mat1)
    S[5] = Sphere(Translation(0.5, -0.5, -0.5) ⊙ Sc, Mat1)
    S[6] = Sphere(Translation(-0.5, 0.5, -0.5) ⊙ Sc, Mat1)
    S[7] = Sphere(Translation(-0.5, -0.5, 0.5) ⊙ Sc, Mat1)
    S[8] = Sphere(Translation(-0.5, -0.5, -0.5) ⊙ Sc, Mat1)
    S[9] = Sphere(Translation(0.0, 0.0, -0.5) ⊙ Sc, Mat2)
    S[10] = Sphere(Translation(0.0, 0.5, 0.0) ⊙ Sc, Mat2)

    R_cam = Rz(cam_angle)
    world = World(S)
    cam = Perspective(d = 2.0, t = R_cam ⊙ Translation(-1.0, 0.0, 0.0))
    hdr = hdrimg(width, height)
    ImgTr = ImageTracer(hdr, cam)

    function flat(ray)
        repo = ray_interception(world, ray)
        return (isnothing(repo)) ? RGB(0.0, 0.0, 0.0) : repo.shape.Mat.Emition(repo.surface_P)
    end

    ImgTr(flat)

    println("Saving image in ", png_output)
    toned_img = tone_mapping(hdr; a = 0.5, lum = 0.5, γ = 1.3)
    # Save the LDR image
    save_ldrimage(get_matrix(toned_img), png_output)
    println("Saved image in ", png_output)
    println("Saving image in ", pfm_output)
    write_pfm_image(hdr, pfm_output)
    println("Done")
end

demo()