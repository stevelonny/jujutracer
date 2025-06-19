using Pkg
project_root = dirname(@__DIR__)
Pkg.activate(project_root)

using jujutracer
using Base.Threads
#using BenchmarkTools

println("Number of threads: ", Threads.nthreads())

width = 1600
height = 900

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

world = World(S)
flat = Flat(world)

@threads for angle in 1:360
    cam_angle = angle * π / 180.0
    cam = Perspective(d = 2.0, t = Rz(cam_angle) ⊙ Translation(-1.0, 0.0, 0.0))
    hdr = hdrimg(width, height)
    ImgTr = ImageTracer(hdr, cam)
    ImgTr(flat)
    # padding
    idx_angle = lpad(string(angle), 3, '0')
    println("Angle: ", idx_angle)
    filename = joinpath(project_root, "demo", "demo_")
    filename *= idx_angle * ".png"
    # check if file exists
    if isfile(filename)
        println("File already exists: ", filename)
        continue
    end
    toned_img = tone_mapping(hdr; a = 0.5, lum = 0.5, γ = 1.3)
    save_ldrimage(get_matrix(toned_img), filename)
end

println("Done")
