#---------------------------------------------------------
# Light source
#---------------------------------------------------------

"""
    struct LightSource
A struct representing a point light source.
# Fields
- `position::Point`: the position of the light source in 3D space.
- `emission::RGB`: the color of the light emitted by the source.
- `scale::Float64`: the scale factor for the light source, affecting its intensity.
# Constructors
- `LightSource(position::Point, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=1.0)`: Creates a new light source with the specified position, emission color, and scale factor.
"""
struct LightSource <: AbstractLight
    position::Point
    emission::RGB
    scale::Float64

    function LightSource(position::Point, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=100.0)
        new(position, emission, scale)
    end
end

"""
    struct SpotLight <: AbstractLight
A struct representing a spotlight source.
# Fields
- `position::Point`: the position of the spotlight in 3D space.
- `direction::Vec`: the direction in which the spotlight is pointing.
- `emission::RGB`: the color of the light emitted by the spotlight.
- `scale::Float64`: the scale factor for the spotlight, affecting its intensity.
- `cos_total::Float64`: the cosine of the angle that defines the total light cone.
- `cos_falloff::Float64`: the cosine of the angle that defines the falloff region of the spotlight.
- `cos_start::Float64`: the cosine of the angle that defines the start of the falloff region.
# Constructors
- `SpotLight(position::Point, direction::Vec, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=100.0, cos_total::Float64=0.9, cos_falloff::Float64=0.93, cos_start::Float64=0.95)`: Creates a new spotlight with the specified parameters.
"""
struct SpotLight <: AbstractLight
    position::Point
    direction::Vec
    emission::RGB
    scale::Float64
    cos_total::Float64
    cos_falloff::Float64

    function SpotLight(position::Point, direction::Vec, emission::RGB=RGB(1.0, 1.0, 1.0), scale::Float64=100.0, cos_total::Float64=0.9, cos_falloff::Float64=0.93)
        new(position, direction, emission, scale, cos_total, cos_falloff)     
    end
end

#---------------------------------------------------------
# Light source functions
#---------------------------------------------------------
"""
    is_light_visible(world::World, light::LightSource, point::Point)
Check if a point is visible from a light source in the given world.
# Arguments
- `world::World`: the world containing the scene.
- `light::LightSource`: the light source to check visibility from.
- `point::Point`: the point to check visibility to.
# Returns
- `Bool`: `true` if the point is visible from the light source, `false` otherwise.
"""
function is_light_visible(world::World, light::LightSource, point::Point)
    return is_point_visible(world, light.position, point)
end

"""
    is_light_visible(world::World, light::SpotLight, point::Point)
Check if a point is visible from a spotlight in the given world.
# Arguments
- `world::World`: the world containing the scene.
- `light::SpotLight`: the spotlight to check visibility from.
- `point::Point`: the point to check visibility to.
# Returns
- `Bool`: `true` if the point is in the cone of light *and* visible, `false` otherwise.
"""
function is_light_visible(world::World, light::SpotLight, point::Point)
    # if the point is not in the light cone, return false
    distance_vec = point - light.position
    cos_angle = Normal(distance_vec) ⋅ Normal(light.direction)
    if cos_angle < light.cos_total
        return false
    else
        # if the point is in the light cone, check if there are any obstacles
        return is_point_visible(world, light.position, point)
    end
end

"""
    _light_modulation(light::LightSource, repo::HitRecord)
Calculate the light modulation for a point light source at a given hit record.
# Arguments
- `light::LightSource`: the light source to calculate modulation for.
- `repo::HitRecord`: the hit record containing the intersection point and normal.
# Returns
- `RGB`: the modulated light color at the hit point.
"""
function _light_modulation(light::LightSource, repo::HitRecord)
    distance_vec = repo.world_P - light.position
    distance = norm(distance_vec)
    cos_theta = max(0.0, -normalize(distance_vec) ⋅ repo.normal)

    distance_factor = (light.scale / distance)^2

    return light.emission * cos_theta * distance_factor
end

"""
    _light_modulation(spot::SpotLight, repo::HitRecord)
Calculate the light modulation for a spotlight at a given hit record.
# Arguments
- `spot::SpotLight`: the spotlight to calculate modulation for.
- `repo::HitRecord`: the hit record containing the intersection point and normal.
# Returns
- `RGB`: the modulated light color at the hit point.
"""
function _light_modulation(spot::SpotLight, repo::HitRecord)
    distance_vec = repo.world_P - spot.position
    distance = norm(distance_vec)
    cos_theta = max(0.0, Normal(spot.direction) ⋅ Normal(distance_vec))

    distance_factor = (spot.scale / distance)^2

    smoothstep = _smooth_step(cos_theta, spot.cos_total, spot.cos_falloff)

    return spot.emission * distance_factor * smoothstep
end

"""
    _smooth_step(x, edge0, edge1)
Calculate a smooth step function value. Used in [`SpotLight`](@ref) for light modulation.
# Arguments
- `x`: the input value.
- `edge0`: the lower edge of the step.
- `edge1`: the upper edge of the step.
# Returns
- `Float64`: the smooth step value, clamped between 0 and 1.
"""
function _smooth_step(x, edge0, edge1)
    t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3 - 2 * t)
end
