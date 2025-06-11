#---------------------------------------------------------
# World type
#---------------------------------------------------------
"""
    struct World

A struct representing a collection of shapes (and lights) in a 3D world.
# Fields
- `shapes::Vector{AbstractShape}`: the vector containing the shapes in the world.
- `lights::Vector{AbstractLight}`: the vector containing the light sources in the world.
# Constructor
- `World()`: creates a new `World` with an empty vector of shapes.
- `World(S::Vector{AbstractShape})`: creates a new `World` with the specified vector of shapes. Lights are initialized to an empty vector.
- `World(S::Vector{AbstractShape}, L::Vector{AbstractLight})`: creates a new `World` with the specified vector of shapes and light sources.
# See also
- [`AbstractShape`](@ref): the abstract type for all shapes.
- [`Sphere`](@ref): a concrete implementation of `AbstractShape` representing a sphere.
- [`Plane`](@ref): a concrete implementation of `AbstractShape` representing a plane.
"""
struct World
    shapes::Vector{AbstractShape}
    lights::Vector{AbstractLight}
    bvh::Union{BVHNode, Nothing}

    function World(shapes::Vector{AbstractShape})
        World(shapes, Vector{AbstractLight}(), nothing)
    end
    function World(shapes::Vector{AbstractShape}, bvh::Union{BVHNode, Nothing})
        World(shapes, Vector{AbstractLight}(), bvh)
    end
    function World(shapes::Vector{AbstractShape}, lights::Vector{AbstractLight})
        @debug "Creating World with shapes: $(length(shapes)) and lights: $(length(lights))"
        new(shapes, lights, nothing)
    end
    function World(shapes::Vector{AbstractShape}, lights::Vector{AbstractLight}, bvh::Union{BVHNode, Nothing})
        @debug "Creating World with shapes: $(length(shapes)), lights: $(length(lights)), and BVH: $(bvh !== nothing)"
        new(shapes, lights, bvh)
    end
end

"""
    ray_intersection(W::World, ray::Ray)

Calculates the intersection of a ray with all shapes in the world.
# Arguments
- `W::World`: the world containing the shapes
- `ray::Ray`: the ray to be intersected with the shapes in the worlds
# Returns
If there is an intersection, returns a `HitRecord` containing the hit information. Otherwise, returns `nothing`.
"""
function ray_intersection(W::World, ray::Ray)
    dim = length(W.shapes)
    closest = nothing

    if !isnothing(W.bvh)
        return ray_intersection_bvh(W.bvh, W.shapes, ray)            
    end

    for i in 1:dim
        inter = ray_intersection(W.shapes[i], ray)
        if isnothing(inter)
            continue
        end
        if (isnothing(closest) || inter.t < closest.t)
            closest = inter
        end
    end

    return closest
end

"""
    is_point_visible(W::World, pos::Point, observer::Point)
Checks if a point is visible from an observer's position in the world.
See also [`is_light_visible`](@ref).
# Arguments
- `W::World`: the world containing the shapes
- `pos::Point`: the position of the point to check visibility for
- `observer::Point`: the position of the observer
# Returns
If the point is visible from the observer's position, returns `true`. Otherwise, returns `false`.
"""
function is_point_visible(W::World, pos::Point, observer::Point)
    direction = pos - observer
    dir_norm = norm(direction)
    ray = Ray(origin=observer, dir=direction, tmin=1e-2 / dir_norm, tmax=1.0)

    for shape in W.shapes
        if quick_ray_intersection(shape, ray)
            return false
        end
    end
    return true
end

