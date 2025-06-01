# AbstractShape is not guaranteed to be water-tight, and cannot be used to create CSG shapes. (for now)
# For example, a plane is not water-tight.

#---------------------------------------------------------
# New Shape
#---------------------------------------------------------
# Remember to add docstrings and tests for the new solid shape
#=
struct NewShape <: AbstractShape
    Tr::AbstractTransformation
    Mat::Material

    function NewShape()
        new(Transformation(), Material())
    end
    function NewShape(Tr::AbstractTransformation)
        new(Tr, Material())
    end
    function NewShape(Mat::Material)
        new(Transformation(), Mat)
    end
    function NewShape(Tr::AbstractTransformation, Mat::Material)
        new(Tr, Mat)
    end
end
=#

# _newshape_normal(p::Point, dir::Vec)
# _point_to_uv(S::NewShape, p::Point)
# ray_intersection(S::NewShape, ray::Ray)
# boxed(S::NewSolid)::Tuple{Point, Point}
# quick_intersection(S::NewShape, ray::Ray)
#=
function boxed(S::NewShape)::Tuple{Point, Point}
    # return P1 and P2 of the bounding box of the circle
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