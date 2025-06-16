# Solid shapes are water-tight, and can be used to create CSG shapes.

#---------------------------------------------------------
# New Solid Shape and methods
#---------------------------------------------------------
# Remember to add docstrings and tests for the new solid shape
#=
struct NewSolid <: AbstractSolid
    Tr::AbstractTransformation
    Mat::Material

    function NewSolid()
        new(Transformation(), Material())
    end
    function NewSolid(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function NewSolid(Mat::Material)
        new(Transformation(), Mat)
    end
    function NewSolid(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end
=#

# _newsolid_normal(p::Point, dir::Vec)
# _point_to_uv(S::NewSolid, p::Point)
# ray_intersection(S::NewSolid, ray::Ray)
# ray_intersection_list(S::NewSolid, ray::Ray)
# internal(S::NewSolid, P::Point)
# boxed(S::NewSolid)::Tuple{Point, Point}
# quick_intersection(S::NewShape, ray::Ray)
#=
function boxed(S::NewSolid)::Tuple{Point, Point}
    # return P1 and P2 of the bounding box of the sphere
    # remember to apply the transformation to the points
    p1 = Point(?)
    p2 = Point(?)
    corners = [
        Point(x, y, z)
        for x in (p1.x, p2.x),
            y in (p1.y, p2.y),
            z in (p1.z, p2.z)
    ]
    # Transform all corners
    world_corners = [S.Tr(c) for c in corners]
    # Find min/max for each coordinate
    xs = [c.x for c in world_corners]
    ys = [c.y for c in world_corners]
    zs = [c.z for c in world_corners]
    Pmin = Point(minimum(xs), minimum(ys), minimum(zs))
    Pmax = Point(maximum(xs), maximum(ys), maximum(zs))
    return (Pmin, Pmax)
end
=#