#---------------------------------------------------------
# World type
#---------------------------------------------------------
"""
    struct World

A struct representing a collection of shapes (and lights) in a 3D world.
# Fields
- `shapes::Vector{Shapes}`: the vector containing the shapes in the world.
- `lights::Vector{LightSource}`: the vector containing the light sources in the world.
# Constructor
- `World()`: creates a new `World` with an empty vector of shapes.
- `World(S::Vector{Shapes})`: creates a new `World` with the specified vector of shapes. Lights are initialized to an empty vector.
- `World(S::Vector{Shapes}, L::Vector{LightSource})`: creates a new `World` with the specified vector of shapes and light sources.
# See also
- [`AbstractShape`](@ref): the abstract type for all shapes.
- [`Sphere`](@ref): a concrete implementation of `AbstractShape` representing a sphere.
- [`Plane`](@ref): a concrete implementation of `AbstractShape` representing a plane.
"""
struct World
    shapes::Vector{AbstractShape}
    lights::Vector{LightSource}

    function World(shapes::Vector{AbstractShape})
        new(shapes, LightSource[])
    end
    function World(shapes::Vector{AbstractShape}, lights::Vector{LightSource})
        new(shapes, lights)
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
