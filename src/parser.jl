mutable struct Scene
    materials::Dict{String, Material}
    wordl::World
    camera::Union{Camera, None}
    float_variables::Dict{String, Float64}
    overridden_variables::Set{String}

    function Scene(
        materials = Dict{String, Material}(),
        world = World(),
        camera = nothing,
        float_variables = Dict{String, Float64}(),
        overridden_variables = Set{String}()
        )
        new(materials, world, camera, float_variables, overridden_variables)
    end
end