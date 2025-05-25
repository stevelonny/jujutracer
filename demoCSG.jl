using Pkg
Pkg.activate(".")

using jujutracer
using BenchmarkTools

if length(ARGS) != 4
    println("Usage: julia demo.jl <output_file> <width> <height> <cam_angle>")
    return
end

println("Number of threads: ", Threads.nthreads())

png_output = ARGS[1]*".png"
width = parse(Int64,ARGS[2])
height = parse(Int64,ARGS[3])
cam_angle = parse(Float64,ARGS[4])
pfm_output = ARGS[1]*".pfm"

function demoCSG(width, height, cam_angle)
    Sc = Scaling(1.0 / 1.5, 1.0 / 1.5, 1.0 / 1.5)
    green = RGB(0.0, 1.0, 0.0)
    red = RGB(1.0, 0.0, 0.0)
    blue = RGB(0.0, 0.0, 1.0)
    yellow = RGB(1.0, 1.0, 0.0)
    cyan = RGB(0.0, 1.0, 1.0)
    magenta = RGB(1.0, 0.0, 1.0)
    gray = RGB(0.5, 0.5, 0.5)
    Mat1 = Material(CheckeredPigment(32, 32, green, red), DiffusiveBRDF(UniformPigment(gray)))
    Mat2 = Material(CheckeredPigment(32, 32, blue, yellow), DiffusiveBRDF(UniformPigment(gray)))
    Mat3 = Material(CheckeredPigment(32, 32, cyan, magenta), DiffusiveBRDF(UniformPigment(gray)))
    S = Vector{AbstractShape}(undef, 4)
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

    S[1] = CSGUnion(Translation(0.0, 0.0, 2.0) ⊙ Rz(0.2) ⊙ Ry(-0.4), (S1 ∪ S2), S3)
    S[2] = CSGDifference(Translation(0.0, 2.0, 0.0) ⊙ Rx(0.4) ⊙ Ry(-0.4), (S1 ∪ S2), S3)
    S[3] = CSGIntersection(Translation(0.0, -2.0, 0.0) ⊙ Ry(0.2) ⊙ Scaling(1.2, 1.2, 1.2), (S1 ∩ S2), S3)
    S[4] = Cylinder(Translation(1.0, 0.0, 0.0) ⊙ Ry(-π / 6.0), Mat1)# - Box(Scaling(1.5, 1.5, 4.0), Mat2)


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

hdr = demoCSG(width, height, cam_angle)

println("Saving image in ", png_output)
toned_img = tone_mapping(hdr; a = 0.5, lum = 0.7, γ = 1.3)
# Save the LDR image
save_ldrimage(get_matrix(toned_img), png_output)
println("Saved image in ", png_output)
println("Saving image in ", pfm_output)
write_pfm_image(hdr, pfm_output)
println("Saved image in ", pfm_output)
println("Done")
