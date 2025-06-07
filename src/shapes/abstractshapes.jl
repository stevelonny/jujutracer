#---------------------------------------------------------
# Shapes
#---------------------------------------------------------
"""
    abstract type AbstractShape

Abstract type for all shapes. Not guaranteed to be water-tight. Cannot be used to create CSG shapes.
See also [`AbstractSolid`](@ref).
"""
abstract type AbstractShape end

"""
    abstract type AbstractSolid <: AbstractShape

Abstract type for solid shapes. Considered water-tight. Can be used to create CSG shapes.
Made concrete by [`Sphere`](@ref), [`Box`](@ref), [`Cylinder`](@ref), [`Cone`](@ref), [`CSGUnion`](@ref), [`CSGDifference`](@ref), and [`CSGIntersection`](@ref).
"""
abstract type AbstractSolid <: AbstractShape end

#---------------------------------------------------------
# Lights
#---------------------------------------------------------
"""
    abstract type AbstractLight
Abstract type for light sources. Made concrete by [`LightSource`](@ref) and [`SpotLight`](@ref).
"""
abstract type AbstractLight end
