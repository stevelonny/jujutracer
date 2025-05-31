
#---------------------------------------------------------
# BRDF Methods
#---------------------------------------------------------

function (BRDF::DiffusiveBRDF)(pcg::PCG, in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    e1, e2, e3 = create_onb_from_z(normal)
    sq = rand_uniform(pcg)
    cos_θ = sqrt(sq)
    sin_θ = sqrt(1.0 - sq)
    ϕ = 2.0 * π * rand_uniform(pcg)

    return Ray(origin = p,
                dir = e1 * cos(ϕ) * cos_θ + e2 * sin(ϕ) * cos_θ + e3 * sin_θ,
                tmin = 10e-3,
                depth = depth)
end

function (BRDF::SpecularBRDF)(pcg::PCG, in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    ray_dir = Vec(Normal(in_dir))
    return Ray(origin = p,
                dir = ray_dir - 2 * normal * (normal ⋅ ray_dir),
                tmin = 10e-3,
                depth = depth)
end

function (U::UniformPigment)(p::SurfacePoint)
    return U.color
end

function (C::CheckeredPigment)(p::SurfacePoint)
    x = floor(Int, p.u * C.col)
    y = floor(Int, p.v * C.row)

    x = (x < C.col) ? x : C.col - 1
    y = (y < C.row) ? y : C.row - 1

    return ((x + y) % 2 == 0) ? C.dark : C.bright
end

function (I::ImagePigment)(p::SurfacePoint)
    x = floor(Int, p.u * I.img.w)
    y = floor(Int, p.v * I.img.h)

    x = (x < I.img.w) ? x : I.img.w - 1
    y = (y < I.img.h) ? y : I.img.h - 1

    return I.img[x, y]
end

#---------------------------------------------------------
# OnOff
#---------------------------------------------------------
"""
    OnOff(world::World)

OnOff renderer of the scene. Returns white if the ray hits something, balck otherwise
# Fields
- `world::World` the world containing the scene
# Functional Usage
`OnOff(ray::Ray)` functional renderer on a ray
"""
struct OnOff <: Function
    world::World
end

function (OF::OnOff)(ray::Ray)
    repo = ray_intersection(OF.world, ray)
    return (isnothing(repo)) ? RGB(0.0, 0.0, 0.0) : RGB(1.0, 1.0, 1.0)
end

#---------------------------------------------------------
# Flat
#---------------------------------------------------------
"""
    Flat(world::World)

Flat renderer of the scene. Returns the Emition pigment of the hitten shapes
# Fields
- `world::World` the world containing the scene
# Functional Usage
`Flat(ray::Ray)` functional renderer on a ray
"""
struct Flat <: Function
    world::World
end

function (F::Flat)(ray::Ray)
    repo = ray_intersection(F.world, ray)
    return (isnothing(repo)) ? RGB(0.0, 0.0, 0.0) : repo.shape.Mat.Emition(repo.surface_P) + repo.shape.Mat.BRDF.Pigment(repo.surface_P)
end

#---------------------------------------------------------
# Path Tracer
#---------------------------------------------------------
"""
    PathTracer(world::World)

Flat renderer of the scene. Returns the Emition pigment of the hitten shapes
# Fields
- `world::World`: the world containing the scene
- `backg::RGB`: the background color when the ray doesn't intersect anything
- `rnd::PCG`: the random number generator
- `n_rays::INt64`: the number of rays fired from the hitten point
- `depth::Int64`: the maximum depth to be reached by a ray
- `russian::Int64`: number of iteration before playing with Russian Roulet
# Functional Usage
`PathTracer(ray::Ray)` functional renderer on a ray
"""
struct PathTracer <: Function
    world::World
    backg::RGB
    rnd::PCG
    n_rays::Int64
    depth::Int64
    russian::Int64
end

function (P::PathTracer)(ray::Ray)
    if ray.depth > P.depth
        return RGB(0.0, 0.0, 0.0)
    end

    repo = ray_intersection(P.world, ray)

    if isnothing(repo) 
        return P.backg
    end
    
    hit_material = repo.shape.Mat
    hit_color = hit_material.BRDF.Pigment(repo.surface_P)
    emitted_r = hit_material.Emition(repo.surface_P)

    hit_color_lum = max(hit_color.r, hit_color.g, hit_color.b)

    if ray.depth >= P.russian
        q = max(0.05, 1 - hit_color_lum)
        if rand_uniform(P.rnd) > q
            hit_color *= 1.0 / (1.0 - q)
        else
            return emitted_r
        end
    end

    cum = RGB(0.0, 0.0, 0.0)
    if hit_color_lum > 0.0
        for i in 1:P.n_rays
            new_ray = hit_material.BRDF(P.rnd, ray.dir, repo.world_P, repo.normal, ray.depth + 1)
            new_rad = P(new_ray) # recursive call
            cum += hit_color * new_rad # a little bit different from slides. Need to verify
        end
    end

    return emitted_r + cum * (1.0 / P.n_rays)
end
