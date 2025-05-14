#---------------------------------------------------------
# Matherial
#---------------------------------------------------------

struct Material
    Emition::AbstractPigment
    BRDF::AbstractBRDF
end

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

function (U::UniformPigment)(p::SurfacePoint)
    return U.color
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

function (C::CheckeredPigment)(p::SurfacePoint)
    x = Int32(p.u * col)
    y = Int32(p.v * row)

    return ((x + y) % 2 == 0) ? C.dark : C.bright
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

function (I::ImagePigment)(p::SurfacePoint)
    x = Int32(p.u * I.img.w)
    y = Int32(p.v * I.img.h)

    return I.img[x, y]
end

#---------------------------------------------------------
# BRDF
#---------------------------------------------------------

abstract type AbstractBRDF end

"""
    DiffusiveBRDF(Pigment::AbstractPigment, R::Float64)

Diffusive BRDF with reflective pigment `Pigment` and refelectance `R`
"""
struct DiffusiveBRDF <: AbstractBRDF
    Pigment::AbstractPigment
    R::Float64
end

"""
    Eval(BRDF::DiffusiveBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, p::SurfacePoint)

Return color of the diffused ray regarldless its icoming or outcoming direction
"""
function Eval(BRDF::DiffusiveBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, p::SurfacePoint)
    return BRDF.Pigment(p) * BRDF.R / π
end 