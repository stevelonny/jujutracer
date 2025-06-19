using Pkg
project_root = dirname(@__DIR__)
Pkg.activate(project_root)

using jujutracer
using Base.Threads
using BenchmarkTools
using Logging
using TerminalLoggers
using LoggingExtras

filename = joinpath(project_root, "Images", "randtriangles_")
width = 1920
height = 1080
n_rays = 4
depth = 5
russian = 3
point_depth = 5
aa = 0
aatype = ""
if aa != 0
    aatype = "_" * string(aa) * "aa"
end
fullname = filename
png_output = filename * ".png"
pfm_output = filename * ".pfm"

green = RGB(0.0, 1.0, 0.0)
red = RGB(1.0, 0.0, 0.0)
blue = RGB(0.0, 0.0, 1.0)
yellow = RGB(1.0, 1.0, 0.0)
magenta = RGB(1.0, 0.0, 1.0)
purple = RGB(0.5, 0.0, 0.5)
gray = RGB(0.2, 0.2, 0.2)
black = RGB(0.0, 0.0, 0.0)
white = RGB(1.0, 1.0, 1.0)

function rand_uniform(pcg::PCG, min::Number, max::Number)::Float64
    min = Float64(min)
    max = Float64(max)
    return min + (max - min) * Float64(rand_pcg(pcg)) / Float64(UInt32(0xffffffff))
end

function generate_point(pcg::PCG)
    return Point(rand_uniform(pcg, -2.0, 2.0), rand_uniform(pcg, -4.0, 4.0), rand_uniform(pcg, -3.0, 3.0))
end

function centroid(A::Point, B::Point, C::Point)
    return Point((A.x + B.x + C.x) / 3, (A.y + B.y + C.y) / 3, (A.z + B.z + C.z) / 3)
end

function color_from_centroid(c::Point)
    # Normalize the centroid coordinates to the range [0, 1]
    r = (c.x + 2.0) / 4.0
    g = (c.y + 4.0) / 8.0
    b = (c.z + 3.0) / 6.0
    # Clamp values to ensure they are within [0, 1]
    r = clamp(r, 0.0, 1.0)
    g = clamp(g, 0.0, 1.0)
    b = clamp(b, 0.0, 1.0)
    return RGB(r, g, b)
end

function random_color(pcg::PCG)
    return RGB(rand_uniform(pcg, 0.0, 1.0), rand_uniform(pcg, 0.0, 1.0), rand_uniform(pcg, 0.0, 1.0))
end

function generate_triangle(pcg::PCG, diffuse::Bool)
    p1 = generate_point(pcg)
    p2 = Point(p1.x + rand_uniform(pcg, -0.5, 0.5), p1.y + rand_uniform(pcg, -0.5, 0.5), p1.z + rand_uniform(pcg, -0.5, 0.5))
    p3 = Point(p1.x + rand_uniform(pcg, -0.5, 0.5), p1.y + rand_uniform(pcg, -0.5, 0.5), p1.z + rand_uniform(pcg, -0.5, 0.5))
    color = color_from_centroid(centroid(p1, p2, p3))
    random_emissive = rand_uniform(pcg, 0.0, 1.0)
    emissive_color = RGB(random_emissive, random_emissive, random_emissive)
    brdf = diffuse ? DiffusiveBRDF(UniformPigment(color)) : SpecularBRDF(UniformPigment(color))
    return Triangle(p1, p2, p3, Material(UniformPigment(emissive_color), brdf))
end
# Create a filtered logger
module_filter(log) = (log._module == jujutracer)
filtered_logger = EarlyFilteredLogger(module_filter, TerminalLogger(stderr, Logging.Debug))

# Set as the global logger
global_logger(filtered_logger)

pcg = PCG()

# generate random triangles
number_of_triangles = 2048
rand_triangles = Vector{AbstractShape}(undef, number_of_triangles)
for i in 1:length(rand_triangles)
    rand_triangles[i] = generate_triangle(pcg, isodd(i))
end

# build the bvh tree
bvh_sah, depth_sah = BuildBVH!(rand_triangles; use_sah=true)
#bvh_simple, depth_simple = BuildBVH!(rand_triangles; use_sah=false)

#max_depth = max(depth_sah, depth_simple)

bvhshape = BVHShape(bvh_sah, rand_triangles)
bvhshapebox = BVHShapeDebug(bvh_sah, rand_triangles)

sky = Sphere(Scaling(10.0, 10.0, 10.0), Material(UniformPigment(RGB(0.5, 0.7, 1.0)), DiffusiveBRDF(UniformPigment(RGB(0.5, 0.7, 1.0)))))

shapes = Vector{AbstractShape}()
push!(shapes, bvhshape)
#push!(shapes, sky)

world = World(shapes)

# rendering 
cam = Perspective(d=2.0, t=Translation(-5.00, 0.0, 0.0))
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)
pcg = PCG()
renderer = nothing
#renderer = Flat(world, RGB(0.1, 0.1, 0.1))
renderer = DepthBVHRender(world; bvh_max_depth=depth_sah)
#renderer = PathTracer(world, RGB(0.1, 0.1, 0.1), pcg, n_rays, depth, russian)
#renderer = PointLight(world, RGB(0.1, 0.1, 0.15), RGB(0.1, 0.1, 0.1), 0)
ImgTr(renderer)

toned_img = tone_mapping(hdr)
# Save the LDR image
save_ldrimage(get_matrix(toned_img), png_output)
write_pfm_image(hdr, pfm_output)
println("Done")