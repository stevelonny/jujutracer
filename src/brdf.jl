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
    DiffusiveBRDF(Pigment::AbstractPigment)

Diffusive BRDF with reflective pigment `Pigment`.
"""
struct DiffusiveBRDF <: AbstractBRDF
    Pigment::AbstractPigment
end

"""
    SpecularBRDF(Pigment::AbstractPigment)

Specular BRDF with reflective pigment `Pigment`.
"""
struct SpecularBRDF <: AbstractBRDF
    Pigment::AbstractPigment
end

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

# ---------------------------------------------------------
# == operators, useful for testing
# ---------------------------------------------------------

function Base.:(==)(p1::AbstractPigment, p2::AbstractPigment)
    if p1 isa UniformPigment && p2 isa UniformPigment
        return p1.color == p2.color
    elseif p1 isa CheckeredPigment && p2 isa CheckeredPigment
        return p1.col == p2.col && p1.row == p2.row && p1.dark == p2.dark && p1.bright == p2.bright
    elseif p1 isa ImagePigment && p2 isa ImagePigment
        return p1.img == p2.img
    else
        return false
    end
end

function Base.:(==)(brdf1::AbstractBRDF, brdf2::AbstractBRDF)
    if brdf1 isa DiffusiveBRDF && brdf2 isa DiffusiveBRDF
        return brdf1.Pigment == brdf2.Pigment
    elseif brdf1 isa SpecularBRDF && brdf2 isa SpecularBRDF
        return brdf1.Pigment == brdf2.Pigment
    else
        return false
    end
end

function Base.:(==)(m1::Material, m2::Material)
    return m1.Emition == m2.Emition && m1.BRDF == m2.BRDF
end