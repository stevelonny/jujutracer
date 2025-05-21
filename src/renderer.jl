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
    return (isnothing(repo)) ? RGB(0.0, 0.0, 0.0) : repo.shape.Mat.Emition(repo.surface_P)
end

#---------------------------------------------------------
# Path Tracer
#---------------------------------------------------------
"""
    Flat(world::World)

Flat renderer of the scene. Returns the Emition pigment of the hitten shapes
# Fields
- `world::World` the world containing the scene
# Functional Usage
`Flat(ray::Ray)` functional renderer on a ray
"""
struct PathTracer <: Function
    world::World
    backg::RGB
    rnd::PCB
    n_rays::Float64
    depth::Int64
    Russian::Int64
end

function (P::PathTracer)(ray::Ray)
    repo = ray_intersection(P.world, ray)
    return (isnothing(repo)) ? RGB(0.0, 0.0, 0.0) : repo.shape.Mat.Emition(repo.surface_P)
end