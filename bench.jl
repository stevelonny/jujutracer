using Pkg
Pkg.activate(".")

using jujutracer
using BenchmarkTools
using Base.Threads

function demo(width, height, cam_angle)
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

    flat = Flat(world)

    ImgTr(flat)

    return hdr
end

function demoCSG(width, height, cam_angle)
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
    S = Vector{AbstractShape}(undef, 3)
    S1 = Sphere(Translation(0.0, 0.5, 0.0) ⊙ Sc, Mat1)
    S2 = Sphere(Translation(0.0, -0.5, 0.0) ⊙ Sc, Mat2)
    S3 = Sphere(Translation(0.0, 0.0, 0.5) ⊙ Sc, Mat3)
    #S[1] = (S1 ∪ S2) ∪ S3
    #S[1] = (S1 ∪ S2) - S3
    #S[1] = (S1 ∩ S2) ∩ S3
    # lets see the substracted part above the first csg figure
    #S[2] = S3 - (S1 ∪ S2)
    #S[1] = S1
    #S[2] = S2
    #S[3] = S3

    S[1] = CSGUnion(Translation(0.0, 0.0, 1.5) ⊙ Rz(0.2) ⊙ Ry(-0.4), (S1 ∪ S2), S3)
    S[2] = CSGDifference(Translation(0.0, 1.0, 0.0) ⊙ Rx(0.4) ⊙ Ry(-0.4), (S1 ∪ S2), S3)
    S[3] = CSGIntersection(Translation(0.0, -1.0, 0.0) ⊙ Ry(0.2) ⊙ Scaling(1.2, 1.2, 1.2), (S1 ∩ S2), S3)


    R_cam = Rz(cam_angle)
    world = World(S)
    #cam = Orthogonal(t = R_cam ⊙ Translation(-1.0, 0.0, 0.0), a_ratio = convert(Float64, 16 // 9))
    cam = Perspective(d = 2.0, t = R_cam ⊙ Translation(-2.5, 0.0, 1.0))
    hdr = hdrimg(width, height)
    ImgTr = ImageTracer(hdr, cam)

    flat = Flat(world)

    #=     function delta(ray)
        repo = ray_intersection(world, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end =#

    ImgTr(flat)

    return hdr
end

println("Number of threads: ", nthreads())

println("Benchmarking demo...")
@btime demo(1920, 1080, 0.0)
println("Benchmarking demoCSG...")
@btime demoCSG(1920, 1080, 0.0)