
#---------------------------------------------------------
# BRDF Methods
#---------------------------------------------------------

function (BRDF::DiffusiveBRDF)(pcg::PCG, in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    e1, e2, e3 = create_onb_from_z(normal)
    sq = rand_uniform(pcg)
    cos_θ = sqrt(sq)
    sin_θ = sqrt(1.0 - sq)
    ϕ = 2.0 * π * rand_uniform(pcg)

    return Ray(origin=p,
        dir=e1 * cos(ϕ) * cos_θ + e2 * sin(ϕ) * cos_θ + e3 * sin_θ,
        tmin=10e-3,
        depth=depth)
end

function (BRDF::SpecularBRDF)(pcg::PCG, in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    ray_dir = Vec(Normal(in_dir))
    return Ray(origin=p,
        dir=ray_dir - 2 * normal * (normal ⋅ ray_dir),
        tmin=10e-3,
        depth=depth)
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
- `background_color::RGB` the color of the background when the ray doesn't hit anything
- `foreground_color::RGB` the color of the foreground when the ray hits something
# Functional Usage
`OnOff(ray::Ray)` functional renderer on a ray
"""
struct OnOff <: Function
    world::World
    background_color::RGB
    foreground_color::RGB
    function OnOff(world::World, background_color::RGB=RGB(0.0, 0.0, 0.0), foreground_color::RGB=RGB(1.0, 1.0, 1.0))
        new(world, background_color, foreground_color)
    end
end

function (OF::OnOff)(ray::Ray)
    repo = ray_intersection(OF.world, ray)
    return (isnothing(repo)) ? OF.background_color : OF.foreground_color
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
    background_color::RGB
    function Flat(world::World, background_color::RGB=RGB(0.0, 0.0, 0.0))
        new(world, background_color)
    end
end

function (F::Flat)(ray::Ray)
    repo = ray_intersection(F.world, ray)
    return (isnothing(repo)) ? F.background_color : repo.shape.Mat.Emition(repo.surface_P) + repo.shape.Mat.BRDF.Pigment(repo.surface_P)
end

#---------------------------------------------------------
# Path Tracer
#---------------------------------------------------------
"""
    PathTracer(world::World, backg::RGB, rnd::PCG, n_rays::Int64, depth::Int64, russian::Int64)

Path Tracer renderer of the scene.
# Fields
- `world::World`: the world containing the scene
- `backg::RGB`: the background color when the ray doesn't intersect anything
- `rnd::PCG`: the random number generator
- `n_rays::Int64`: the number of rays fired from the hitten point
- `depth::Int64`: the maximum depth to be reached by a ray
- `russian::Int64`: number of iteration before playing with Russian Roulet
# Functional Usage
`PathTracer(ray::Ray)` functional renderer on a ray
"""
struct PathTracer <: Function
    world::World
    background_color::RGB
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
        return P.background_color
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

#---------------------------------------------------------
# Point-light tracing
#---------------------------------------------------------

struct PointLight <: Function
    world::World
    background_color::RGB
    ambient_color::RGB
    max_depth::Int64

    function PointLight(world::World, background::RGB=RGB(0.0, 0.0, 0.0), ambient=RGB(0.2, 0.2, 0.2), max_depth::Int64=0)
        new(world, background, ambient, max_depth)
    end
end

function (PL::PointLight)(ray::Ray)
    repo = ray_intersection(PL.world, ray)
    if isnothing(repo)
        return PL.background_color
    end
    if ray.depth > PL.max_depth
        return PL.background_color
    end

    hit_material = repo.shape.Mat
    emitted_color = hit_material.Emition(repo.surface_P)
    result_color = RGB(0.0, 0.0, 0.0)

    if ray.depth == 0
        result_color += emitted_color + PL.ambient_color
    end

    if hit_material.BRDF isa DiffusiveBRDF
        for cur_light in PL.world.lights
            if is_point_visible(PL.world, cur_light.position, repo.world_P)
                light_effect = _light_modulation(cur_light, repo)
                brdf_color = hit_material.BRDF.Pigment(repo.surface_P) *(1.0/π)

                result_color += brdf_color * light_effect
            end
        end
    end

    if hit_material.BRDF isa SpecularBRDF
        reflected_ray = _reflect_ray(ray, repo.normal)
        reflected_color = PL(reflected_ray)
        brdf_color = hit_material.BRDF.Pigment(repo.surface_P)
        result_color += reflected_color * brdf_color
    end

    return result_color
end

function _reflect_ray(ray::Ray, normal::Normal)
    incoming_dir = ray.dir
    reflected_dir = incoming_dir - 2 * normal * (normal ⋅ incoming_dir)
    # translate the reflected ray just a little bit to avoid self-intersection
    reflected_origin = ray.origin + 1e-5 * reflected_dir
    return Ray(origin=reflected_origin, dir=reflected_dir, tmin=1e-5, depth=ray.depth + 1)
end

function _light_modulation(light::LightSource, repo::HitRecord)
    distance_vec = repo.world_P - light.position
    distance = norm(distance_vec)
    cos_theta = max(0.0, -normalize(distance_vec) ⋅ repo.normal)

    distance_factor = (light.scale / distance)^2
    
    return light.emission * cos_theta * distance_factor
end