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

filename = "tree_"
renderertype = "point" # "path" or "flat"
width = 720
height = 1280
n_rays = 3
depth = 5
russian = 3
point_depth = 5
aa = 2
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


Sc = Scaling(1.0 / 1.5, 1.0 / 1.5, 1.0 / 1.5)
sky = read_pfm_image("sky.pfm")
bark = read_pfm_image("bark.pfm")
black = RGB(0.0, 0.0, 0.0)
red = RGB(0.5, 0.0, 0.0)
gray = RGB(0.5, 0.5, 0.5)
yellow = RGB(0.5, 0.5, 0.0)
MatGround = Material(UniformPigment(black), DiffusiveBRDF(UniformPigment(RGB(0.2, 0.3, 0.2))))
MatSky = Material(ImagePigment(sky), DiffusiveBRDF(UniformPigment(black)))
MatTree = Material(UniformPigment(black), DiffusiveBRDF(ImagePigment(bark)))
MatSphere = Material(UniformPigment(black), SpecularBRDF(UniformPigment(RGB(1.0, 1.0, 1.0))))
S = Vector{AbstractShape}(undef, 4)

sky = Sphere(Scaling(18.0, 18.0, 18.0) ⊙ Ry(-π / 4.0), MatSky)
sphere = Sphere(Translation(4.0, 2.0, 0.0), MatSphere)
ground = Plane(MatGround)
tree = mesh("tree.obj", Translation(-5.0, 0.0, -0.05) ⊙ Scaling(1.0 / 1.3, 1.0 / 1.3, 1.0 / 1.3), MatTree)
tree_shapes = Vector{AbstractShape}()
for t in tree.shapes
    push!(tree_shapes, t)
end
bvh, bvhdepth = BuildBVH!(tree_shapes; use_sah=true)
bvhshape = BVHShape(bvh, tree_shapes)

A, B = bvh.p_min, bvh.p_max
spot_O = Point(B.x, A.y, 16.0)
A = Point(A.x, B.y, 0.0)
cos_total = cos(π / 8.0)
cos_falloff = cos(π / 12.0)
spot = SpotLight(spot_O, (A-spot_O), RGB(1.0, 1.0, 0.8), 100.0)


shapes = Vector{AbstractShape}()
push!(shapes, sky)
push!(shapes, sphere)
push!(shapes, ground)
push!(shapes, bvhshape)

lights = Vector{AbstractLight}()
push!(lights, spot)

world = World(shapes, lights, nothing)

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

cam = Perspective(d=2.0, t=Translation(-6.0, 0.0, 2.0) ⊙ Ry(-π / 10.0), a_ratio=9/16)
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)

if aa != 0
    ImgTr(renderer, aa, pcg)
else
    ImgTr(renderer)
end

toned_img = tone_mapping(hdr)
save_ldrimage(get_matrix(toned_img), png_output)
write_pfm_image(hdr, pfm_output)
println("Done")
