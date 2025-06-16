using Pkg
Pkg.activate(".")

using jujutracer
using Base.Threads
using BenchmarkTools
using Logging
using TerminalLoggers
using LoggingExtras

# Create a filtered logger
module_filter(log) = log._module == jujutracer || log.level > Logging.Debug
filtered_logger = EarlyFilteredLogger(module_filter, TerminalLogger(stderr, Logging.Debug))

# Set as the global logger
global_logger(filtered_logger)

if length(ARGS) != 4
    println("Usage: julia demoPath.jl <output_file> <width> <height> <cam_angle>")
    return
end


png_output = ARGS[1] * ".png"
width = parse(Int64, ARGS[2])
height = parse(Int64, ARGS[3])
cam_angle = parse(Float64, ARGS[4])
pfm_output = ARGS[1] * ".pfm"

Sc = Scaling(1.0 / 1.5, 1.0 / 1.5, 1.0 / 1.5)
green = RGB(0.0, 1.0, 0.0)
red = RGB(1.0, 0.0, 0.0)
blue = RGB(0.0, 0.0, 1.0)
yellow = RGB(1.0, 1.0, 0.0)
sky = RGB(0.4, 0.7, 1.0)
sky = read_pfm_image("asset/sky.pfm")
magenta = RGB(1.0, 0.0, 1.0)
gray = RGB(0.5, 0.5, 0.5)
black = RGB(0.0, 0.0, 0.0)
Mat1 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(8, 8, gray, yellow)))
Mat2 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(12, 12, magenta, blue)))
Mat3 = Material(UniformPigment(black), SpecularBRDF(UniformPigment(red)))
Mat4 = Material(ImagePigment(sky), DiffusiveBRDF(UniformPigment(gray)))
S = Vector{AbstractShape}(undef, 4)

S[1] = Sphere(Scaling(7.0, 7.0, 7.0) ⊙ Ry(-π / 4.0), Mat4)
S[2] = Sphere(Translation(0.0, 0.0, 1.0), Mat2)
S[3] = Sphere(Translation(0.0, 2.0, 0.0) ⊙ Sc, Mat3)
S[4] = Plane(Mat1)


R_cam = Rz(cam_angle)
world = World(S)
#cam = Orthogonal(t = R_cam ⊙ Translation(-1.0, 0.0, 0.0), a_ratio = convert(Float64, 16 // 9))
cam = Perspective(d=2.0, t=R_cam ⊙ Translation(-1.5, 0.0, 1.0) ⊙ Ry(-π / 10.0))
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)
pcg = PCG()

path = PathTracer(world, gray, pcg, 2, 5, 2)
#flat = Flat(world)
ImgTr(path, 2, pcg)

toned_img = tone_mapping(hdr; a=0.5, lum=0.5, γ=1.3)
# Save the LDR image
save_ldrimage(get_matrix(toned_img), png_output)
write_pfm_image(hdr, pfm_output)
println("Done")
