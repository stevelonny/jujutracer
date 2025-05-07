struct HitRecord
    world_P::Point
    normal::Normal
    surface_P::Tuple{Float64,Float64}
    t::Float64
    ray::Ray

    function HitRecord(; world_P::Point, normal::Normal, surface_P::Tuple{Float64,Float64}, t::Float64, ray::Ray)
        new(world_P, normal,surface_P, t, ray)
    end
end

abstract type shape end

struct Sphere <: shape
    Tr::Transformation
end

function (S::Sphere)(ray::Ray)
    inv_ray = inverse(Tr)(ray)
    O = inv_ray.origin
    d = inv_ray.dir
    Δrid = (O⋅d)^2 - squared_norm(d)*(squared_norm(O) - 1)
    if Δrid > 0
        t1 = (- O⋅d - sqrt(Δrid))/squared_norm(d)
        t2 = (- O⋅d + sqrt(Δrid))/squared_norm(d)
        if t1 > inv_ray.tmin && t1 < inv_ray.tmax
            first_hit = t1
            if t2 > inv_ray.tmin && t2 < t1
                first_hit = t2
            end
        elseif t2 > inv_ray.tmin && t2 < inv_ray.tmax
            first_hit = t2
        end
    end
    hit_point = inv_ray(first_hit)
    return HitRecord(
        world_P = Tr(hit_point),
        normal = Tr(_sphere_normal(hit_point, ray)),
        surface_P = _sphere_to_uv(hit_point),
        t = first_hit,
        ray = ray
    )
end

function _sphere_normal(p::Point, ray::Ray)
    return _adj_normal(Normal(p), ray)
end

function _adj_normal(p, ray::Ray)
    if Vec(p)⋅ray.dir < 0
        return p
    else 
        return -p
    end
end

function _sphere_to_uv(p::Point)
    return (p⋅p,-p⋅p) # write casual thing, to be implemented
end