include("abstractshapes.jl")
export AbstractShape, AbstractSolid

include("flatcircle.jl")
export Circle

include("flatplane.jl")
export Plane

include("flatrectangle.jl")
export Rectangle

include("solidsphere.jl")
export Sphere

include("solidbox.jl")
export Box

include("solidcylinder.jl")
export Cylinder

include("solidcone.jl")
export Cone

include("world.jl")
export World

include("hitrecord.jl")
export SurfacePoint, HitRecord




export ray_intersection, ray_intersection_list, Eval, boxed

import Base:
    ≈
