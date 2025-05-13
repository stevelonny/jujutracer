using Pkg
Pkg.activate(".")

using jujutracer

function demo2()
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

    S = Vector{AbstractShape}(undef, 1)
    S1 = Sphere(Translation(0.0, 0.5, 0.0) ⊙ Sc)
    S2 = Sphere(Translation(0.0, -0.5, 0.0) ⊙ Sc)
    S3 = Sphere(Translation(0.0, 0.0, 0.5) ⊙ Sc)
    S[1] = (S1 ∪ S2) - S3

    R_cam = Rz(cam_angle)
    world = World(S)
    cam = Perspective(d = 2.0, t = R_cam ⊙ Ry(0.8) ⊙ Translation(-1.0, 0.0, 0.0))
    hdr = hdrimg(width, height)
    ImgTr = ImageTracer(hdr, cam)

    function delta(ray)
        repo = ray_intersection(world, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end

    ImgTr(delta)

    println("Saving image in ", png_output)
    toned_img = tone_mapping(hdr; a=0.18, γ=2.2)
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

demo2()