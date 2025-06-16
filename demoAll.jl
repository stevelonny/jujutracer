using Pkg
Pkg.activate(".")

using jujutracer
using Base.Threads
using BenchmarkTools
using Logging
using TerminalLoggers
using LoggingExtras

# Create a filtered logger
module_filter(log) = (log._module == jujutracer)
filtered_logger = EarlyFilteredLogger(module_filter, TerminalLogger(stderr, Logging.Debug))

# Set as the global logger
global_logger(filtered_logger)

# Welcome to steve's playground

filename = "all_"
renderertype = "point" # "path" or "flat" or "point"
width = 1280
height = 720
n_rays = 3
depth = 5
russian = 3
point_depth = 1000
aa = 0
aatype = ""
if aa != 0
    aatype = "_" * string(aa) * "aa"
end
fullname = filename
if renderertype == "flat"
    fullname = fullname * "flat_" * string(width) * "x" * string(height) * aatype
elseif renderertype == "path"
    fullname = fullname * "path_" * string(width) * "x" * string(height) * aatype * "_" * string(n_rays) * "rays_" * string(depth) * "depth_" * string(russian) * "rus" * aatype
elseif renderertype == "point"
    fullname = fullname * "point_" * string(width) * "x" * string(height) * aatype * "_" * string(point_depth) * "depth"
else
    throw(ArgumentError("Invalid renderer type. Use 'flat' or 'path'."))
end
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
sky = read_pfm_image("sky.pfm")
MatSky = if renderertype == "point"
    Material(UniformPigment(gray), DiffusiveBRDF(ImagePigment(sky)))
else
    Material(ImagePigment(sky), DiffusiveBRDF(UniformPigment(RGB(0.1, 0.1, 0.1))))
end
Mat1 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(6, 6, gray, green)))
Mat2 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(12, 12, magenta, blue)))
Mat3 = Material(UniformPigment(black), SpecularBRDF(UniformPigment(white)))
Mat4 = Material(UniformPigment(gray), DiffusiveBRDF(UniformPigment(white)))
Mat5 = Material(UniformPigment(black), DiffusiveBRDF(CheckeredPigment(10, 10, black, gray)))
MatCone = Material(UniformPigment(black), SpecularBRDF(CheckeredPigment(12, 12, red, green)))
MatBox = Material(UniformPigment(black), SpecularBRDF(UniformPigment(red)))
MatT = Material(UniformPigment(black), SpecularBRDF(UniformPigment(green)))
MatPara = Material(UniformPigment(black), SpecularBRDF(UniformPigment(blue)))
MatRect = Material(UniformPigment(black), SpecularBRDF(UniformPigment(magenta)))

S = Vector{AbstractShape}()
S_back = Sphere(Scaling(7.0, 7.0, 7.0) ⊙ Ry(-π / 4.0), MatSky)
B1 = Box(Translation(-0.25, 0.0, 1.0) ⊙ Rz(π / 4.0), Mat5)
S1 = Sphere(Translation(-0.25, 0.0, 1.0) ⊙ Sc, Mat3)
S2 = Sphere(Translation(-0.25, 0.0, 1.0) ⊙ Scaling(1.0 / 2.5, 1.0 / 2.5, 1.0 / 2.5), Mat4)
T1 = Triangle(Point(1.5, 1.5, 2.0), Point(0.5, 2.5, 2.0), Point(0.5, 2.0, 3.0), MatT)
M1 = mesh("humanoid_tri.obj", Translation(1.5, 2.5, 0.0) ⊙ Scaling(0.1, 0.1, 0.1) ⊙ Translation(0.0, 0.0, -3.05), MatBox)
M2 = mesh("humanoid_quad.obj", Translation(0.5, 1.5, 0.0) ⊙ Scaling(0.1, 0.1, 0.1) ⊙ Translation(0.0, 0.0, -3.05), MatPara)
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
axisBox4 = AABB(M1)
axisBox5 = AABB(M2)
Co1 = Cone(Scaling(1.0 / 2.5, 1.0 / 2.5, 1.0 / 2.5) ⊙ Translation(-2.0 * 2.5, 2.0 * 2.5, 1.02 * 2.5) ⊙ Ry(π) ⊙ Rx(π / 3.0), MatCone)
Ci1 = Circle(Translation(0.0, 0.0, 0.01), MatRect)
R1 = Rectangle(Translation(-2.5, 0.0, 0.01), MatRect)

factor = 100.0

lights = Vector{AbstractLight}()
light1 = LightSource(Point(2.0, 2.0, 2.0), RGB(0.5, 0.0, 0.0), factor)
light2 = LightSource(Point(2.0, -2.0, 2.0), RGB(0.0, 0.5, 0.0), factor)
light3 = LightSource(Point(-2.0, 0.0, 3.0), RGB(0.0, 0.0, 0.5), factor)
light4 = LightSource(Point(0.0, 0.0, 6.90), RGB(0.1, 0.1, 0.1), factor/2.0)
origin = Point(0.0, 0.0, 0.0)
A = Point(3.0, 3.0, 5.0)
B = Point(3.0, -3.0, 5.0)
C = Point(-3.0, 0.0, 5.0)
cos_total = cos(π / 8.0)
cos_falloff = cos(π / 12.0)
# cos_start = cos(π / 9.0)
spot1 = SpotLight(A, -Vec(A), RGB(0.0, 0.5, 0.0), factor, cos_total, cos_falloff)
spot2 = SpotLight(B, -Vec(B), RGB(0.5, 0.0, 0.0), factor, cos_total, cos_falloff)
spot3 = SpotLight(C, -Vec(C), RGB(0.0, 0.0, 0.5), factor, cos_total, cos_falloff)
#push!(lights, light1)
#push!(lights, light2)
#push!(lights, light3)
push!(lights, light4)
push!(lights, spot1)
push!(lights, spot2)
push!(lights, spot3)

push!(S, S_back)
push!(S, axisBox)
push!(S, axisBox3)
push!(S, T1)
push!(S, axisBox4)
push!(S, axisBox5)
push!(S, Para1)
push!(S, axisBox2)
push!(S, Co1)
push!(S, Ci1)
push!(S, R1)
push!(S, Plane(Mat5))

world = World(S, lights)
#cam = Orthogonal(t = R_cam ⊙ Translation(-1.0, 0.0, 0.0), a_ratio = convert(Float64, 16 // 9))
cam = Perspective(d=2.0, t=Translation(-3.25, 0.0, 1.5) ⊙ Ry(π / 6.0))
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)
pcg = PCG()
renderer = nothing
if renderertype == "flat"
    renderer = Flat(world)
elseif renderertype == "path"
    renderer = PathTracer(world, gray, pcg, n_rays, depth, russian)
elseif renderertype == "point"
    renderer = PointLight(world, RGB(0.5, 0.7, 1.0), RGB(0.1, 0.1, 0.1), point_depth)
else
    throw(ArgumentError("Invalid renderer type. Use 'flat' or 'path'."))
end
if aa != 0
    ImgTr(renderer, aa, pcg)
else
    ImgTr(renderer)
end
luminosity = jujutracer._average_luminosity(hdr; type="W")
toned_img = tone_mapping(hdr; lum=luminosity)
# Save the LDR image
save_ldrimage(get_matrix(toned_img), png_output)
write_pfm_image(hdr, pfm_output)
println("Done")