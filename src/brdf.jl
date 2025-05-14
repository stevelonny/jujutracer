#---------------------------------------------------------
# Pigment
#---------------------------------------------------------

abstract type AbstractPigment end

"""
    UniformPigment()

Uniform Pigment for Shapes
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
    CheckeredPigment(row::Int32, col::Int32, dark::RGB, bright::RGB)

Checkered pigment for a Shape, subdiveded in `row` rows and `col` columns with alternate `dark` and `bright` color
"""
struct CheckeredPigment <: AbstractPigment
    row::Int32
    col::Int32
    dark::RGB
    bright::RGB
end