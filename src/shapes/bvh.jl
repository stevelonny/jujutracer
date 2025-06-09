mutable struct BVHNode
    p_min::Point
    p_max::Point
    left::Union{BVHNode,Nothing}
    right::Union{BVHNode,Nothing}
    first_index::Int64
    last_index::Int64
    function BVHNode(first_index::Int64, last_index::Int64)
        new(Point(Inf, Inf, Inf), Point(-Inf, -Inf, -Inf), nothing, nothing, first_index, last_index)
    end
end

function UpdateBoundaries!(node::BVHNode, shapes::Vector{AbstractShape})
    pmin = Point(Inf, Inf, Inf)
    pmax = Point(-Inf, -Inf, -Inf)
    for i in node.first_index:node.last_index
        P1, P2 = boxed(shapes[i])
        pmin = Point(min(pmin.x, P1.x), min(pmin.y, P1.y), min(pmin.z, P1.z))
        pmax = Point(max(pmax.x, P2.x), max(pmax.y, P2.y), max(pmax.z, P2.z))
    end
    node.p_min = pmin
    node.p_max = pmax
end

function Subdivide!(node::BVHNode, shapes::Vector{AbstractShape}, centroids::Vector{Point})
    if node.last_index - node.first_index + 1 <= 1
        return
    end

    extent = node.p_max - node.p_min
    axis = 1 # x-axis
    if extent.y > extent.x
        axis = 2  # y-axis
    end
    if extent.z > getfield(extent, axis)
        axis = 3  # z-axis
    end
    split_pos = getfield(node.p_min, axis) + getfield(extent, axis) * 0.5

    left_index = node.first_index
    right_index = node.last_index
    while left_index <= right_index
        if getfield(centroids[left_index], axis) < split_pos
            left_index += 1
        else
            if left_index < right_index
                centroids[left_index], centroids[right_index] = centroids[right_index], centroids[left_index]
                shapes[left_index], shapes[right_index] = shapes[right_index], shapes[left_index]
            end
            right_index -= 1
        end
    end

    if left_index - node.first_index <= 0 || node.last_index - right_index <= 0
        return
    end

    node.left = BVHNode(node.first_index, left_index - 1)
    node.right = BVHNode(left_index, node.last_index)
    UpdateBoundaries!(node.left, shapes)
    UpdateBoundaries!(node.right, shapes)

    Subdivide!(node.left, shapes, centroids)
    Subdivide!(node.right, shapes, centroids)
end

function BuildBVH(shapes::Vector{AbstractShape}, centroids::Vector{Point})
    root = BVHNode(1, length(shapes))
    @debug "Created root node" root = root

    UpdateBoundaries!(root, shapes)
    Subdivide!(root, shapes, centroids)

    return root
end

function ray_intersection_aabb(pmin::Point, pmax::Point, ray::Ray)
    p1 = pmin
    p2 = pmax
    O = ray.origin
    d = ray.dir

    t1x = (p1.x - O.x) / d.x
    t2x = (p2.x - O.x) / d.x
    t1y = (p1.y - O.y) / d.y
    t2y = (p2.y - O.y) / d.y
    t1z = (p1.z - O.z) / d.z
    t2z = (p2.z - O.z) / d.z

    tmin = max(min(t1x, t2x), min(t1y, t2y), min(t1z, t2z))
    tmax = min(max(t1x, t2x), max(t1y, t2y), max(t1z, t2z))

    if tmax < max(ray.tmin, tmin)
        return false
    end

    first_hit = tmin > ray.tmin ? tmin : tmax
    return first_hit <= ray.tmax
end

function ray_intersection_bvh(bvh::BVHNode, shapes::Vector{AbstractShape}, ray::Ray)
    if !ray_intersection_aabb(bvh.p_min, bvh.p_max, ray)
        return nothing
    end

    if isnothing(bvh.left) && isnothing(bvh.right)
        closest = nothing
        for i in bvh.first_index:bvh.last_index
            hit = ray_intersection(shapes[i], ray)
            if !isnothing(hit) && (isnothing(closest) || hit.t < closest.t)
                closest = hit
            end
        end
        return closest
    end

    left_hit = !isnothing(bvh.left) ? ray_intersection_bvh(bvh.left, shapes, ray) : nothing
    right_hit = !isnothing(bvh.right) ? ray_intersection_bvh(bvh.right, shapes, ray) : nothing

    if isnothing(left_hit) && isnothing(right_hit)
        return nothing
    elseif isnothing(left_hit)
        return right_hit
    elseif isnothing(right_hit)
        return left_hit
    else
        return left_hit.t < right_hit.t ? left_hit : right_hit
    end
end

struct BVHShape <: AbstractShape
    bvhroot::BVHNode
    shapes::Vector{AbstractShape}
end

function ray_intersection(bvhshape::BVHShape, ray::Ray)
    return ray_intersection_bvh(bvhshape.bvhroot, bvhshape.shapes, ray)
end