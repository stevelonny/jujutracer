#---------------------------------------------------------
# Pigment
#---------------------------------------------------------

abstract type AbstractPigment end

"""
    UniformPigment()

Uniform Pigment for Shapes
# Fields
- `color::RBG` the uniform color

# Functional Usage
`UniformPigment(p::SurfacePoint)` return the `RGB` associated to the `(u, v)` coordinates of the `SurfacePoint`
Methods in [`renderer.jl`](@ref)
"""
struct UniformPigment <: AbstractPigment
    color::RGB

    function UniformPigment(color::RGB)
        new(color)
    end

    function UniformPigment()
        new(RGB(1.0, 1.0, 1.0))
    end
end


"""
    CheckeredPigment(col::Int32, row::Int32, dark::RGB, bright::RGB)

Checkered pigment for a Shape, subdiveded in `row` rows and `col` columns with alternate `dark` and `bright` color
# Fields
- `col` number of horizontal subdivisions
- `row` number of vertical subdivisions
- `dark` color of the dark squares
- `bright` color of the bright squares

# Functional Usage
`CheckeredPigment(p::SurfacePoint)` return the `RGB` associated to the `(u, v)` coordinates of the `SurfacePoint` 

Methods in [`renderer.jl`](@ref)
"""
struct CheckeredPigment <: AbstractPigment
    col::Int32
    row::Int32
    dark::RGB
    bright::RGB
end


"""
    ImagePigment(img::hdrimg)

Print the image `img` as pigment of the surface
# Fields
- `img::hdrimg` the image in hdr format
# Functional Usage
`ImagePigment(p::SurfacePoint)` return the `RGB` of to the `(u, v)` coordinates of the `SurfacePoint` associated to the corresponding element of `img`

"""
struct ImagePigment <: AbstractPigment
    img::hdrimg
end

#---------------------------------------------------------
# BRDF
#---------------------------------------------------------

abstract type AbstractBRDF end

"""
    DiffusiveBRDF(Pigment::AbstractPigment, R::Float64)

Diffusive BRDF with reflective pigment `Pigment`.
"""
struct DiffusiveBRDF <: AbstractBRDF
    Pigment::AbstractPigment
end

"""
    SpecularBRDF(Pigment::AbstractPigment, R::Float64)

Specular BRDF with reflective pigment `Pigment`.
"""
struct SpecularBRDF <: AbstractBRDF
    Pigment::AbstractPigment
end

# Pigment and BRDF methods are in [`renderer.jl`](@ref)

#---------------------------------------------------------
# Material
#---------------------------------------------------------

"""
    struct Material

# Fields
- `Emition::AbstractPigment`: the pigement with which the radiation is emitted.
- `BRDF::AbstractBRDF`: the BRDF of the material.
"""
struct Material
    Emition::AbstractPigment
    BRDF::AbstractBRDF

    function Material()
        new(
            UniformPigment(RGB(1.0, 1.0, 1.0)),
            DiffusiveBRDF(UniformPigment(RGB(1.0, 1.0, 1.0)))
        )
    end
    function Material(Emition::AbstractPigment, BRDF::AbstractBRDF)
        new(Emition, BRDF)
    end
end
