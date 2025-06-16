
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

function (BRDF::SpecularBRDF)(in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    return _reflect_ray(in_dir, p, normal, depth)
end

function (BRDF::SpecularBRDF)(pcg::PCG, in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    return _reflect_ray(in_dir, p, normal, depth)
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

"""
    _reflect_ray(in_dir::Vec, p::Point, normal::Normal, depth::Int64)
"""
function _reflect_ray(in_dir::Vec, p::Point, normal::Normal, depth::Int64)
    incoming_dir = Vec(Normal(in_dir))
    reflected_dir = incoming_dir - 2 * normal * (normal ⋅ incoming_dir)
    return Ray(origin=p, dir=reflected_dir, tmin=1e-5, depth=depth)
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
"""
    PointLight(world::World, background::RGB, ambient::RGB, max_depth::Int64)
PointLight renderer of the scene. Backtraces the light from the point light sources.
# Fields
- `world::World`: the world containing the scene. Must contain at least one light source
- `background_color::RGB`: the color of the background when the ray doesn't hit anything
- `ambient_color::RGB`: the ambient color of the scene
- `max_depth::Int64`: the maximum depth of the ray tracing
# Functional Usage
`PointLight(ray::Ray)` functional renderer on a ray
"""
struct PointLight <: Function
    world::World
    background_color::RGB
    ambient_color::RGB
    max_depth::Int64

    function PointLight(world::World, background::RGB=RGB(0.0, 0.0, 0.0), ambient=RGB(0.2, 0.2, 0.2), max_depth::Int64=0)
        if isempty(world.lights)
            throw(ArgumentError("World must contain at least one light source for PointLight renderer."))
        end
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
            if is_light_visible(PL.world, cur_light, repo.world_P)
                light_effect = _light_modulation(cur_light, repo)
                # lambertian reflectance
                brdf_color = hit_material.BRDF.Pigment(repo.surface_P) * (1.0 / π)

                result_color += brdf_color * light_effect
            end
        end
    end

    if hit_material.BRDF isa SpecularBRDF
        reflected_ray = hit_material.BRDF(ray.dir, repo.world_P, repo.normal, ray.depth + 1)
        reflected_color = PL(reflected_ray)
        # should it be multiplied by the specular color? where is / π?
        brdf_color = hit_material.BRDF.Pigment(repo.surface_P)
        result_color += reflected_color * brdf_color
    end

    return result_color
end

#---------------------------------------------------------
# DepthBVHRender
#---------------------------------------------------------

"""
    DepthBVHRender(world::World; background_color::RGB=RGB(0.1, 0.1, 0.1), non_bvh_color::RGB=RGB(1.0, 0.0, 0.0), 
                   bvh_color_low::RGB=RGB(0.0, 0.0, 1.0), bvh_color_high::RGB=RGB(1.0, 1.0, 0.0), bvh_max_depth::Int64)
DepthBVHRender renderer of the scene. Renders the depth of the BVH tree. Useful for debugging and visualization of the BVH structure.
Use this when rendereing a [`BVHShapeDebug`](@ref).
# Fields
- `world::World`: the world containing the scene. Must contain at least one BVHShape
- `background_color::RGB`: the color of the background when the ray doesn't hit anything
- `non_bvh_color::RGB`: the color of the ray when it hits a shape that is not part of the BVH
- `bvh_color_low::RGB`: the color of the ray when it hits a shape that is part of the BVH with low depth
- `bvh_color_high::RGB`: the color of the ray when it hits a shape that is part of the BVH with high depth
- `bvh_max_depth::Int64`: the maximum depth of the BVH tree. Used to normalize the depth value
# Functional Usage
`DepthBVHRender(ray::Ray)` functional renderer on a ray
"""
struct DepthBVHRender <: Function
    world::World
    background_color::RGB
    non_bvh_color::RGB
    bvh_color_low::RGB
    bvh_color_high::RGB
    bvh_max_depth::Int64

    function DepthBVHRender(world::World; background_color::RGB=RGB(0.1, 0.1, 0.1), non_bvh_color::RGB=RGB(1.0, 0.0, 0.0), 
                            bvh_color_low::RGB=RGB(0.0, 0.0, 1.0), bvh_color_high::RGB=RGB(1.0, 1.0, 0.0), bvh_max_depth::Int64)
        new(world, background_color, non_bvh_color, bvh_color_low, bvh_color_high, bvh_max_depth)
    end

end

function (DBR::DepthBVHRender)(ray::Ray)
    repo = ray_intersection(DBR.world, ray)
    if isnothing(repo)
        return DBR.background_color
    end
    if isnothing(repo.bvh_depth)
        return DBR.non_bvh_color
    end
    v_color = clamp(repo.bvh_depth / DBR.bvh_max_depth, 0.0, 1.0)
    result_color = DBR.bvh_color_low * (1.0 - v_color) + DBR.bvh_color_high * v_color
    return result_color
end
