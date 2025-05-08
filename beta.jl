using Pkg
Pkg.activate(".")

using jujutracer

function demo()
    Sc = Scaling(1. / 10., 1. / 10., 1. / 10.)

    S = Vector{Shape}(undef, 10)
    S[1] = Sphere(Translation(0.5, 0.5, 0.5) ⊙ Sc)
    S[2] = Sphere(Translation(-0.5, 0.5, 0.5) ⊙ Sc)
    S[3] = Sphere(Translation(0.5, -0.5, 0.5) ⊙ Sc)
    S[4] = Sphere(Translation(0.5, 0.5, -0.5) ⊙ Sc)
    S[5] = Sphere(Translation(0.5, -0.5, -0.5) ⊙ Sc)
    S[6] = Sphere(Translation(-0.5, 0.5, -0.5) ⊙ Sc)
    S[7] = Sphere(Translation(-0.5, -0.5, 0.5) ⊙ Sc)
    S[8] = Sphere(Translation(-0.5, -0.5, -0.5) ⊙ Sc)
    S[9] = Sphere(Translation(0.0, 0.0, -0.5) ⊙ Sc)
    S[10] = Sphere(Translation(0.0, 0.5, 0.0) ⊙ Sc)


    world = World(S)
    cam = Perspective(d=2.0, t=Translation(-1.0, 0.0, 0.0))
    hdr = hdrimg(1600, 900)
    ImgTr = ImageTracer(hdr, cam)

    function delta(ray)
        repo = ray_interception(world, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end

    ImgTr(delta)

    println("Saving image in blacktriangle.png")
    toned_img = tone_mapping(hdr; a=0.18, γ=2.2)
    # Save the LDR image
    save_ldrimage(get_matrix(toned_img), "blacktriangle.png")
    # write_pfm_image(hdr, "blacktriangle.pfm")
    println("Done")
end

demo()