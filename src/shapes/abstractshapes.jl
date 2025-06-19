#---------------------------------------------------------
# Shapes
#---------------------------------------------------------
"""
    AbstractShape

Abstract type for all shapes. Not guaranteed to be water-tight. Cannot be used to create CSG shapes.
See also [`AbstractSolid`]().
"""
abstract type AbstractShape end

"""
    AbstractSolid <: AbstractShape

Abstract type for solid shapes. Considered water-tight. Can be used to create CSG shapes.
Made concrete by [`Sphere`](), [`Box`](), [`Cylinder`](), [`Cone`](), [`CSGUnion`](), [`CSGDifference`](), and [`CSGIntersection`]().
"""
abstract type AbstractSolid <: AbstractShape end

#---------------------------------------------------------
# Lights
#---------------------------------------------------------
"""
    AbstractLight
Abstract type for light sources. Made concrete by [`LightSource`]() and [`SpotLight`]().
"""
abstract type AbstractLight end
