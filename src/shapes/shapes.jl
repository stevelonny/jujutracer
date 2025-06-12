include("abstractshapes.jl")
export AbstractShape, AbstractSolid, AbstractLight

include("flatcircle.jl")
export Circle

include("flatplane.jl")
export Plane

include("flatrectangle.jl")
export Rectangle

include("flattriangle.jl")
export Triangle, _sarrus

include("flatparallelogram.jl")
export Parallelogram

include("solidsphere.jl")
export Sphere

include("solidbox.jl")
export Box

include("solidcylinder.jl")
export Cylinder

include("solidcone.jl")
export Cone

include("csg.jl")
export CSGUnion, CSGDifference, CSGIntersection

include("aabb.jl")
export AABB, intersected

include("meshes.jl")
export mesh

include("bvh.jl")
export BVHNode, BuildBVH, ray_intersection_bvh, ray_intersection_aabb, BVHShape, ray_intersection, centroid

include("world.jl")
export World

include("hitrecord.jl")
export SurfacePoint, HitRecord

include("light.jl")
export LightSource, SpotLight

export ray_intersection, ray_intersection_list, internal, boxed, quick_ray_intersection, is_point_visible

import Base:
    ≈
