using Pkg
Pkg.activate(".")

using jujutracer
using Base.Threads
using BenchmarkTools
using Logging
using TerminalLoggers
using LoggingExtras

function centroid(t::Triangle)
    return Point((t.A.x + t.B.x + t.C.x) / 3, (t.A.y + t.B.y + t.C.y) / 3, (t.A.z + t.B.z + t.C.z) / 3)
end
function centroid(A::Point, B::Point, C::Point)
    return Point((A.x + B.x + C.x) / 3, (A.y + B.y + C.y) / 3, (A.z + B.z + C.z) / 3)
end

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

tree_shapes = Vector{AbstractShape}()
for t in m_tree.shapes
    push!(tree_shapes, t)
end

tree_shapes = deepcopy(tree_shapes)

bvh, primitves = BuildBVH(tree_shapes; use_sah=false)
bvhshape = BVHShape(bvh, tree_shapes, primitves)
box = Box(bvhshape.bvhroot.p_min, bvhshape.bvhroot.p_max, Material(UniformPigment(RGB(0.5, 0.3, 0.1)), DiffusiveBRDF(UniformPigment(RGB(0.5, 0.3, 0.1)))))

sun_material = Material(UniformPigment(RGB(1.0, 1.0, 0.8)), DiffusiveBRDF(UniformPigment(RGB(1.0, 1.0, 0.8))))

sun = Sphere(Translation(10.0, 4.5, 16.0), sun_material)
spot = SpotLight(Point(10.0, 4.5, 16.0), Vec(-10.0, -4.5, -16.0), RGB(1.0, 1.0, 0.8), 100.0)
A, B = box.P2, box.P1
spot = SpotLight(A, (B-A), RGB(1.0, 1.0, 0.8), 100.0)
light = LightSource(A, RGB(0.2, 0.2, 0.12), 100.0)


shapes = Vector{AbstractShape}()
push!(shapes, Plane(Material(UniformPigment(RGB(0.0, 0.0, 0.0)), DiffusiveBRDF(UniformPigment(RGB(0.1, 0.2, 0.1))))))
push!(shapes, sun) # remove it if using point light
# push!(shapes, box)
push!(shapes, bvhshape)
lights = Vector{AbstractLight}()
push!(lights, spot)
push!(lights, light)

world = World(shapes, lights, nothing)

cam = Perspective(d=1.0, t=Translation(-3.0, 0.0, 7.5), a_ratio=9/16)
hdr = hdrimg(width, height)
ImgTr = ImageTracer(hdr, cam)
pcg = PCG()
renderer = Flat(world, RGB(0.1, 0.1, 0.1))
#renderer = PathTracer(world, RGB(0.1, 0.1, 0.1), pcg, n_rays, depth, russian)
#renderer = PointLight(world, RGB(0.1, 0.1, 0.15), RGB(0.1, 0.1, 0.1), 0)
ImgTr(renderer)

toned_img = tone_mapping(hdr)
save_ldrimage(get_matrix(toned_img), png_output)
write_pfm_image(hdr, pfm_output)
println("Done")




