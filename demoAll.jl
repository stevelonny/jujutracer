using Pkg
Pkg.activate(".")

using jujutracer
using Base.Threads
using BenchmarkTools

# Welcome to steve's playground

filename = "all_"
renderer = "flat" # or "flat"
width = 640
height = 360
n_rays = 2
depth = 3
russian = 2
aa = 2
fullname = filename * renderer * "_" * string(width) * "x" * string(height) * "_" * string(n_rays) * "rays_" * string(depth) * "depth_" * string(russian) * "rus_" * string(aa) * "aa"
png_output = fullname * ".png"
pfm_output = fullname * ".pfm"

Sc = Scaling(1.0 / 1.6, 1.0 / 1.6, 1.0 / 1.6)
green = RGB(0.0, 1.0, 0.0)
red = RGB(1.0, 0.0, 0.0)
blue = RGB(0.0, 0.0, 1.0)
yellow = RGB(1.0, 1.0, 0.0)
magenta = RGB(1.0, 0.0, 1.0)
purple = RGB(0.5, 0.0, 0.5)
gray = RGB(0.2, 0.2, 0.2)
black = RGB(0.0, 0.0, 0.0)
white = RGB(1.0, 1.0, 1.0)
super_white = RGB(10.0, 10.0, 10.0)
Mat1 = Material(UniformPigment(black), SpecularBRDF(CheckeredPigment(6, 6, gray, green)))
Mat2 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(12, 12, magenta, blue)))
Mat3 = Material(UniformPigment(black), SpecularBRDF(UniformPigment(white)))
Mat4 = Material(UniformPigment(super_white), DiffusiveBRDF(UniformPigment(white)))
Mat5 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(10, 10, purple, yellow)))
MatCone = Material(UniformPigment(black), SpecularBRDF(CheckeredPigment(12, 12, red, green)))
MatBox = Material(UniformPigment(black), SpecularBRDF(UniformPigment(red)))
MatT = Material(UniformPigment(black), SpecularBRDF(UniformPigment(green)))
MatPara = Material(UniformPigment(black), SpecularBRDF(UniformPigment(blue)))
MatRect = Material(UniformPigment(black), SpecularBRDF(UniformPigment(magenta)))

S = Vector{AbstractShape}()
S_back = Sphere(Scaling(7.0, 7.0, 7.0) ⊙ Ry(-π / 4.0), Mat1)
B1 = Box(Translation(-0.25, 0.0, 1.0) ⊙ Rz(π / 4.0), Mat5)
S1 = Sphere(Translation(-0.25, 0.0, 1.0) ⊙ Sc, Mat3)
S2 = Sphere(Translation(-0.25, 0.0, 1.0) ⊙ Scaling(1.0 / 2.5, 1.0 / 2.5, 1.0 / 2.5), Mat4)
T1 = Triangle(Point(1.5, 1.5, 0.0), Point(0.5, 2.5, 0.0), Point(0.5, 2.0, 1.0), MatT)
Para1 = Parallelogram(Point(1.5, -1.5, 0.0), Point(0.5, -2.5, 0.0), Point(0.5, -2.0, 1.0), MatPara)
CSG = (B1 - S1) ∪ S2
B2 = Box(Rz(π / 4.0), MatBox)
B3 = Box(Translation(0.0, 0.0, 0.5) ⊙ Rz(π / 4.0), Mat5)
Cy1 = Cylinder(Ry(-π / 6.0) ⊙ Rx(-π / 6.0) ⊙ Scaling(1.0 / 2.5, 1.0 / 2.5, 1.5), MatCone)
Cy2 = Cylinder(Ry(-π / 6.0) ⊙ Rx(-π / 6.0) ⊙ Scaling(1.0 / 4.5, 1.0 / 4.5, 1.5), MatPara)
CSG2 = CSGUnion(Translation(-2.75, -1.5, 1.0) ⊙ Sc ⊙ Rz(-π / 6.0), B2 - Cy1, Cy2)
Co2 = Cone(MatCone)
S3 = Sphere(Translation(0.0, -0.5, 1.0) ⊙ Scaling(1.0 / 2.0, 1.0 / 2.0, 1.0 / 2.0), Mat3)
CSG3 = CSGDifference(Translation(-2.5, 1.5, 0.0) ⊙ Sc, B3 ∪ Co2, S3)
axisBox = AABB(CSG)
axisBox2 = AABB(CSG2)
axisBox3 = AABB(CSG3)
Co1 = Cone(Scaling(1.0 / 2.5, 1.0 / 2.5, 1.0 / 2.5) ⊙ Translation(-2.0 * 2.5, 2.0 * 2.5, 1.02 * 2.5) ⊙ Ry(π) ⊙ Rx(π / 3.0), MatCone)
Ci1 = Circle(Translation(0.0, 0.0, 0.01), MatRect)
R1 = Rectangle(Translation(-2.5, 0.0, 0.01), MatRect)

push!(S, S_back)
push!(S, axisBox)
push!(S, axisBox3)
push!(S, T1)
push!(S, Para1)
push!(S, axisBox2)
push!(S, Co1)
push!(S, Ci1)
push!(S, R1)
push!(S, Plane(Mat5))

world = World(S)
#cam = Orthogonal(t = R_cam ⊙ Translation(-1.0, 0.0, 0.0), a_ratio = convert(Float64, 16 // 9))
cam = Perspective(d=2.0, t=Translation(-3.25, 0.0, 1.5) ⊙ Ry(π / 6.0))
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)
pcg = PCG()
renderer = nothing
if renderer == "flat"
    renderer = Flat(world)
elseif renderer == "path"
    renderer = PathTracer(world, gray, pcg, n_rays, depth, russian)
else
    throw(ArgumentError("Invalid renderer type. Use 'flat' or 'path'."))
end
ImgTr(rendere, aa, pcg)
luminosity = jujutracer._average_luminosity(hdr; type="W")
@info "Average luminosity: " luminosity
toned_img = tone_mapping(hdr; a=0.5, γ=1.3)
# Save the LDR image
save_ldrimage(get_matrix(toned_img), png_output)
@info "Saved image in " png_output
write_pfm_image(hdr, pfm_output)
@info "Saved image in " pfm_output