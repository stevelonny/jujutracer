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

filename = "output"
width = 900
height = 1600
n_rays = 4
depth = 5
russian = 3
point_depth = 5
aa = 2
png_output = filename * ".png"
pfm_output = filename * ".pfm"

m_tree = mesh("tree.obj", Material(UniformPigment(RGB(0.0, 0.0, 0.0)), DiffusiveBRDF(UniformPigment(RGB(0.5, 0.3, 0.1)))))

shapes = Vector{AbstractShape}()
for t in m_mesh.shapes
    push!(shapes, t)
end

bvh, bvhdepth = BuildBVH!(shapes; use_sah=true)
bvhshape = BVHShape(bvh, shapes)
box = Box(bvhshape.bvhroot.p_min, bvhshape.bvhroot.p_max, Material(UniformPigment(RGB(0.5, 0.3, 0.1)), DiffusiveBRDF(UniformPigment(RGB(0.5, 0.3, 0.1)))))

sun_material = Material(UniformPigment(RGB(1.0, 1.0, 0.8)), DiffusiveBRDF(UniformPigment(RGB(1.0, 1.0, 0.8))))

sun = Sphere(Translation(10.0, 4.5, 16.0), sun_material)
spot = SpotLight(Point(10.0, 4.5, 16.0), Vec(-10.0, -4.5, -16.0), RGB(1.0, 1.0, 0.8), 100.0)
A, B = box.P2, box.P1
spot = SpotLight(A, (B-A), RGB(1.0, 1.0, 0.8), 100.0)
light = LightSource(A, RGB(0.2, 0.2, 0.12), 100.0)

ground_material = Material(UniformPigment(RGB(0.0, 0.0, 0.0)), DiffusiveBRDF(CheckeredPigment(2, 2, RGB(0.2, 0.2, 0.2), RGB(0.7, 0.7, 0.7))))

w_shapes = Vector{AbstractShape}()
push!(w_shapes, Plane(ground_material))
#push!(w_shapes, sun) # remove it if using point light
# push!(w_shapes, box)
push!(w_shapes, bvhshape)
lights = Vector{AbstractLight}()
push!(lights, spot)
push!(lights, light)

world = World(w_shapes, lights, nothing)

cam = Perspective(d=1.0, t=Translation(-6.0, 0.0, 2.0), a_ratio=16/9)
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)
#pcg = PCG()
renderer = Flat(world, RGB(0.1, 0.1, 0.1))
#renderer = DepthBVHRender(world; bvh_max_depth=bvhdepth)
#renderer = PathTracer(world, RGB(0.1, 0.1, 0.1), pcg, n_rays, depth, russian)
#renderer = PointLight(world, RGB(0.1, 0.1, 0.15), RGB(0.1, 0.1, 0.1), 0)
ImgTr(renderer)

toned_img = tone_mapping(hdr)
save_ldrimage(get_matrix(toned_img), png_output)
write_pfm_image(hdr, pfm_output)
println("Done")
