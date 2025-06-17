#--------------------------------------------------------------------
# Boundary Volume Hierarchy
#--------------------------------------------------------------------

"""
    mutable struct BVHNode
A node in the Boundary Volume Hierarchy (BVH) tree.
# Fields
- `p_min::Point`: The minimum point of the bounding box.
- `p_max::Point`: The maximum point of the bounding box.
- `left::Union{BVHNode,Nothing}`: The left child node.
- `right::Union{BVHNode,Nothing}`: The right child node.
- `first_index::Int64`: The index of the first shape in this node.
- `last_index::Int64`: The index of the last shape in this node.
# Constructor
- `BVHNode(first_index::Int64, last_index::Int64)`: Creates a new BVHNode with the specified indices and initializes the bounding box to infinity.
"""
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

function Base.show(io::IO, node::BVHNode)
    print(io, "BVHNode(p_min=$(node.p_min), p_max=$(node.p_max), first_index=$(node.first_index), last_index=$(node.last_index))")
end

"""
    centroid(t::AbstractShape)
Calculate the centroid of a shape `t` using the [`boxed`](@ref) method.
# Arguments
- `t::AbstractShape`: The shape for which to calculate the centroid.
# Returns
- `Point`: The centroid of the shape.
"""
function centroid(t::AbstractShape)
    p1, p2 = boxed(t)
    return Point((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0, (p1.z + p2.z) / 2.0)
end

"""
    surface_area(p1::Point, p2::Point)
Calculate the surface area of a bounding box defined by two points `p1` and `p2`.
# Arguments
- `p1::Point`: The first point defining the bounding box.
- `p2::Point`: The second point defining the bounding box.
# Returns
- `Float64`: The surface area of the bounding box.
"""
function surface_area(p1::Point, p2::Point)
    if p1.x == Inf || p2.x == -Inf
        return 0.0
    end
    diagonal = p2 - p1
    if diagonal.x < 0 || diagonal.y < 0 || diagonal.z < 0
        return 0.0
    end
    return 2 * (diagonal.x * diagonal.y + diagonal.x * diagonal.z + diagonal.y * diagonal.z)
end

"""
    offset(p::Point, pmin::Point, pmax::Point)
Calculate the normalized offset of a point `p` within the bounding box defined by `pmin` and `pmax`.   
# Arguments
- `p::Point`: The point to offset.
- `pmin::Point`: The minimum point of the bounding box.
- `pmax::Point`: The maximum point of the bounding box.
# Returns
- `Point`: The offset point normalized within the bounding box.
"""
function offset(p::Point, pmin::Point, pmax::Point)
    o = p - pmin
    if pmax.x > pmin.x
        o = Point(o.x / (pmax.x - pmin.x), o.y, o.z)
    end
    if pmax.y > pmin.y
        o = Point(o.x, o.y / (pmax.y - pmin.y), o.z)
    end
    if pmax.z > pmin.z
        o = Point(o.x, o.y, o.z / (pmax.z - pmin.z))
    end
    return o
end

"""
    UpdateBoundaries!(node::BVHNode, shapes::Vector{AbstractShape})
Update the bounding box of a BVH node `node` based on the shapes contained within it.
# Arguments
- `node::BVHNode`: The BVH node whose bounding box is to be updated.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree.
"""
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
    #@debug "Updated boundaries for node" node = node p_min = pmin p_max = pmax first_index = node.first_index last_index = node.last_index
end

"""
    Subdivide!(node::BVHNode, shapes::Vector{AbstractShape}, centroids::Vector{Point}, depth::Int64; max_shapes_per_leaf::Int64=2)
Subdivide a BVH node into left and right child nodes based on the centroids of the shapes. Recursive method.
# Arguments
- `node::BVHNode`: The BVH node to subdivide.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree. **Note: it will be modified in place.**
- `centroids::Vector{Point}`: The centroids of the shapes.
- `depth::Int64`: The current depth of the BVH tree.
# Keyword Arguments
- `max_shapes_per_leaf::Int64=2`: The maximum number of shapes allowed in a leaf node.
# Returns
- `Int64`: The maximum depth of the BVH tree after subdivision.
"""
function Subdivide!(node::BVHNode, shapes::Vector{AbstractShape}, centroids::Vector{Point}, depth::Int64; max_shapes_per_leaf::Int64=2)
    depth += 1
    if node.last_index - node.first_index + 1 <= max_shapes_per_leaf
        # create a leaf node
        node.left = nothing
        node.right = nothing
        return depth
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

    # equivalet to std::partition!
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
        return depth
    end

    node.left = BVHNode(node.first_index, left_index - 1)
    node.right = BVHNode(left_index, node.last_index)
    UpdateBoundaries!(node.left, shapes)
    UpdateBoundaries!(node.right, shapes)

    left_depth = Subdivide!(node.left, shapes, centroids, depth; max_shapes_per_leaf=max_shapes_per_leaf)
    right_depht = Subdivide!(node.right, shapes, centroids, depth; max_shapes_per_leaf=max_shapes_per_leaf)

    # return the maximum depth of the tree
    if left_depth > right_depht
        return left_depth
    else
        return right_depht
    end
end

"""
    SubdivideSAH!(node::BVHNode, shapes::Vector{AbstractShape}, centroids::Vector{Point}, depth::Int64; max_shapes_per_leaf::Int64=2, n_buckets::Int64=12)
Subdivide a BVH node using the Surface Area Heuristic (SAH) method. Recursive method.
# Arguments
- `node::BVHNode`: The BVH node to subdivide.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree. **Note: it will be modified in place.**
- `centroids::Vector{Point}`: The centroids of the shapes.
- `depth::Int64`: The current depth of the BVH tree.
# Keyword Arguments
- `max_shapes_per_leaf::Int64=2`: The maximum number of shapes allowed in a leaf node.
- `n_buckets::Int64=12`: The number of buckets to use for SAH.
# Returns
- `Int64`: The maximum depth of the BVH tree after subdivision.
"""
function SubdivideSAH!(node::BVHNode, shapes::Vector{AbstractShape}, centroids::Vector{Point}, depth::Int64; max_shapes_per_leaf::Int64=2, n_buckets::Int64=12)
    depth += 1
    # stop if there are too few shapes
    num_shapes = node.last_index - node.first_index + 1
    if num_shapes <= max_shapes_per_leaf
        #= b_points = Vector{Tuple{Point, Point}}(undef, num_shapes)
        for i in node.first_index:node.last_index
            b_points[i - node.first_index + 1] = boxed(shapes[i])
        end
        @debug "Creating leaf node" node = node b_points = b_points =#
        return depth
    end

    # chose split axis
    extent = node.p_max - node.p_min
    axis = 1 # x-axis
    if extent.y > extent.x
        axis = 2  # y-axis
    end
    if extent.z > getfield(extent, axis)
        axis = 3  # z-axis
    end

    if num_shapes <= 2
        # split in half if there are 2 or fewer shapes
        split_pos = getfield(node.p_min, axis) + getfield(extent, axis) * 0.5
        if num_shapes == 2
            # swap shapes if they are not in the correct order
            if getfield(centroids[node.first_index], axis) > split_pos
                centroids[node.first_index], centroids[node.last_index] = centroids[node.last_index], centroids[node.first_index]
                shapes[node.first_index], shapes[node.last_index] = shapes[node.last_index], shapes[node.first_index]
            end
            node.left = BVHNode(node.first_index, node.first_index)
            node.right = BVHNode(node.first_index + 1, node.last_index)
            UpdateBoundaries!(node.left, shapes)
            UpdateBoundaries!(node.right, shapes)
            return depth
        else # num_shapes == 1
            node.left = BVHNode(node.first_index, node.first_index)
            node.right = nothing
            UpdateBoundaries!(node.left, shapes)
            return depth + 1
        end
    else
        # initialize buckets for SAH
        p_a_min = getfield(node.p_min, axis)
        p_a_max = getfield(node.p_max, axis)
        extent_axis = p_a_max - p_a_min
        bucket_count = Vector{Int64}(undef, n_buckets)
        bucket_bounds = Vector{Tuple{Point,Point}}(undef, n_buckets)
        for i in 1:n_buckets
            bucket_count[i] = 0
            bucket_bounds[i] = (Point(Inf, Inf, Inf), Point(-Inf, -Inf, -Inf))
        end
        for i in node.first_index:node.last_index
            centroid_offset = offset(centroids[i], node.p_min, node.p_max)
            b = min(floor(Int64, n_buckets * getfield(centroid_offset, axis)) + 1, n_buckets)
            if b > n_buckets
                b = n_buckets
            end
            bucket_count[b] += 1
            P1, P2 = boxed(shapes[i])

            if bucket_count[b] == 1
                bucket_bounds[b] = (P1, P2)
            else
                bucket_bounds[b] = (
                    Point(min(bucket_bounds[b][1].x, P1.x), min(bucket_bounds[b][1].y, P1.y), min(bucket_bounds[b][1].z, P1.z)),
                    Point(max(bucket_bounds[b][2].x, P2.x), max(bucket_bounds[b][2].y, P2.y), max(bucket_bounds[b][2].z, P2.z))
                )
            end
        end
        total_bucketed_shapes = 0
        for i in 1:n_buckets
            total_bucketed_shapes += bucket_count[i]
        end
        #@debug "Total bucketed shapes: $(total_bucketed_shapes) out of $(num_shapes)"
        #@debug "Bucket counts and bounds: $(bucket_count) $(bucket_bounds)"
        for i in 1:n_buckets
            if bucket_count[i] == 0
                # no shapes in this bucket, set bounds to empty
                bucket_bounds[i] = (Point(Inf, Inf, Inf), Point(-Inf, -Inf, -Inf))
            end
        end
        # forward scan to assing costs (first part of the cost equation)
        n_splits = n_buckets - 1
        costs = Vector{Float64}(undef, n_splits)
        count_below = 0
        bound_below = (Point(Inf, Inf, Inf), Point(-Inf, -Inf, -Inf))
        for i in 1:n_splits
            bound_below = (
                Point(min(bound_below[1].x, bucket_bounds[i][1].x), min(bound_below[1].y, bucket_bounds[i][1].y), min(bound_below[1].z, bucket_bounds[i][1].z)),
                Point(max(bound_below[2].x, bucket_bounds[i][2].x), max(bound_below[2].y, bucket_bounds[i][2].y), max(bound_below[2].z, bucket_bounds[i][2].z))
            )
            count_below += bucket_count[i]
            costs[i] = count_below * surface_area(bound_below[1], bound_below[2])
        end
        # backward scan to assign costs (second part of the cost equation)
        count_above = 0
        bound_above = (Point(Inf, Inf, Inf), Point(-Inf, -Inf, -Inf))
        for i in n_splits:-1:1
            bound_above = (
                Point(min(bound_above[1].x, bucket_bounds[i+1][1].x), min(bound_above[1].y, bucket_bounds[i+1][1].y), min(bound_above[1].z, bucket_bounds[i+1][1].z)),
                Point(max(bound_above[2].x, bucket_bounds[i+1][2].x), max(bound_above[2].y, bucket_bounds[i+1][2].y), max(bound_above[2].z, bucket_bounds[i+1][2].z))
            )
            count_above += bucket_count[i+1]
            costs[i] += count_above * surface_area(bound_above[1], bound_above[2])
        end
        # find the best split
        best_split = 0 #-1
        best_cost = Inf
        for i in 1:n_splits
            if costs[i] < best_cost
                best_cost = costs[i]
                best_split = i
            end
        end

        leaf_cost = num_shapes
        # 0.5 = traversal cost (arbitrarianly set)
        best_cost = 0.5 + best_cost / surface_area(node.p_min, node.p_max)
        # either:
        # - split if:
        #   - the cost is lower than the leaf cost
        #   - or the number of shapes is greater than max_shapes_per_leaf
        # - or create a leaf node
        #@debug "Processing node with:" n_buckets=n_buckets p_max = node.p_max p_min = node.p_min axis = axis best_split = best_split best_cost = best_cost leaf_cost = leaf_cost left= node.first_index right = node.last_index
        if (best_cost < leaf_cost || num_shapes > max_shapes_per_leaf)
            # reorder shapes and centroids
            left_index = node.first_index
            right_index = node.last_index
            while left_index <= right_index
            centroid_offset = offset(centroids[left_index], node.p_min, node.p_max)
            b = min(floor(Int64, n_buckets * getfield(centroid_offset, axis)) + 1, n_buckets)
            if b > n_buckets
                b = n_buckets
            end
                if b <= best_split
                    left_index += 1
                else
                    centroids[left_index], centroids[right_index] = centroids[right_index], centroids[left_index]
                    shapes[left_index], shapes[right_index] = shapes[right_index], shapes[left_index]
                    right_index -= 1
                end
            end #while
            if left_index - node.first_index <= 0 || node.last_index - right_index <= 0
                #@debug "No valid split found, creating leaf node"
                return depth
            end

            node.left = BVHNode(node.first_index, left_index - 1)
            node.right = BVHNode(left_index, node.last_index)

            
            UpdateBoundaries!(node.left, shapes)
            left_depth = SubdivideSAH!(node.left, shapes, centroids, depth; max_shapes_per_leaf=max_shapes_per_leaf)
            
            UpdateBoundaries!(node.right, shapes)
            right_depth = SubdivideSAH!(node.right, shapes, centroids, depth; max_shapes_per_leaf=max_shapes_per_leaf)

            # return the maximum depth of the tree
            if left_depth > right_depth
                return left_depth
            else
                return right_depth
            end

        else # create a leaf node
            return depth
        end
    end
end

"""
    BuildBVH!(shapes::Vector{AbstractShape}; use_sah::Bool=false, max_shapes_per_leaf::Int64=2, n_buckets::Int64=12)
Build a Boundary Volume Hierarchy (BVH) tree from a vector of shapes.
# Arguments
- `shapes::Vector{AbstractShape}`: The vector of shapes to build the BVH from. **Note: it will be modified in place.**
# Keyword Arguments
- `use_sah::Bool=false`: Whether to use the Surface Area Heuristic (SAH) for subdivision.
- `max_shapes_per_leaf::Int64=2`: The maximum number of shapes allowed in a leaf node.
- `n_buckets::Int64=12`: The number of buckets to use for SAH.
# Returns
- `(BVHNode, Int64)`: A tuple containing the root node of the BVH tree and the maximum depth of the tree.
"""
function BuildBVH!(shapes::Vector{AbstractShape}; use_sah::Bool=false, max_shapes_per_leaf::Int64=2, n_buckets::Int64=12)
    root = BVHNode(1, length(shapes))
    @debug "Building BVH tree" shapes = length(shapes) max_shapes_per_leaf = max_shapes_per_leaf use_sah = use_sah n_buckets = n_buckets

    centroids = [centroid(s) for s in shapes]

    depth = 0
    starting_time = time_ns()
    UpdateBoundaries!(root, shapes)
    if use_sah
        depth = SubdivideSAH!(root, shapes, centroids, depth; max_shapes_per_leaf=max_shapes_per_leaf, n_buckets=n_buckets)
    else
        depth = Subdivide!(root, shapes, centroids, depth)
    end
    @debug "BVH tree built" depth = depth time = (time_ns() - starting_time) / 1e9
    return root, depth
end

"""
    ray_intersection_aabb(pmin::Point, pmax::Point, ray::Ray)
Check if a ray intersects with an Axis-Aligned Bounding Box (AABB) defined by `pmin` and `pmax`.
# Arguments
- `pmin::Point`: The minimum point of the AABB.
- `pmax::Point`: The maximum point of the AABB.
- `ray::Ray`: The ray to check for intersection.
# Returns
- `Bool`: `true` if the ray intersects the AABB, `false` otherwise.
"""
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

"""
    ray_intersection_bvh(bvh::BVHNode, shapes::Vector{AbstractShape}, ray::Ray, bvh_depth::Int64)
Check if a ray intersects with the BVH tree `bvh` containing the shapes in `shapes`.
# Arguments
- `bvh::BVHNode`: The root node of the BVH tree.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree.
- `ray::Ray`: The ray to check for intersection.
- `bvh_depth::Int64`: The current depth of the BVH tree.
# Returns
- `HitRecord` or `nothing`: A `HitRecord` if the ray intersects a shape in the BVH, or `nothing` if it does not. The `bvh_depth` field of the `HitRecord` will be populated.
"""
function ray_intersection_bvh(bvh::BVHNode, shapes::Vector{AbstractShape}, ray::Ray, bvh_depth::Int64)
    bvh_depth += 1
    
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
        
        if !isnothing(closest)
            return HitRecord(
                world_P=closest.world_P,
                normal=closest.normal,
                surface_P=closest.surface_P,
                t=closest.t,
                ray=closest.ray,
                shape=closest.shape,
                bvh_depth=bvh_depth
            )
        end
        return nothing
    end

    left_hit = !isnothing(bvh.left) ? ray_intersection_bvh(bvh.left, shapes, ray, bvh_depth) : nothing
    right_hit = !isnothing(bvh.right) ? ray_intersection_bvh(bvh.right, shapes, ray, bvh_depth) : nothing

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

"""
    struct BVHShape <: AbstractShape
Shape that holds a BVH tree and the relative shapes.
# Fields
- `bvhroot::BVHNode`: The root node of the BVH tree.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree.
# Constructor
- `BVHShape(bvhroot::BVHNode, shapes::Vector{AbstractShape})`: Creates a new `BVHShape` with the specified BVH root and shapes.
"""
struct BVHShape <: AbstractShape
    bvhroot::BVHNode
    shapes::Vector{AbstractShape}
end

"""
    ray_intersection(bvhshape::BVHShape, ray::Ray)
Check if a ray intersects with the BVHShape `bvhshape`.
# Arguments
- `bvhshape::BVHShape`: The BVHShape containing the BVH tree and shapes.
- `ray::Ray`: The ray to check for intersection.
# Returns
- `HitRecord` or `nothing`: A `HitRecord` if the ray intersects a shape in the BVHShape, or `nothing` if it does not. The `bvh_depth` field of the `HitRecord` will be populated.
"""
function ray_intersection(bvhshape::BVHShape, ray::Ray)
    return ray_intersection_bvh(bvhshape.bvhroot, bvhshape.shapes, ray, 0)
end

"""
    quick_ray_intersection(bvhshape::BVHShape, ray::Ray)
Check if a ray intersects with the BVHShape `bvhshape` using an optimized method that only checks the bounding box.
# Arguments
- `bvhshape::BVHShape`: The BVHShape containing the BVH tree and shapes.
- `ray::Ray`: The ray to check for intersection.
# Returns
- `Bool`: `true` if the ray intersects the bounding box of the BVHShape, `false` otherwise.
"""
function quick_ray_intersection(bvhshape::BVHShape, ray::Ray)
    return !isnothing(ray_intersection_bvh(bvhshape.bvhroot, bvhshape.shapes, ray, 0))
end

# stack traversal + early exits
function ray_intersection_bvh_optimized(bvh::BVHNode, shapes::Vector{AbstractShape}, ray::Ray)
    # prepare a stack for traversal
    nodesToVisit = Vector{BVHNode}()
    sizehint!(nodesToVisit, 64) # preallocate stack size (prob useless as i cant allocate on the stack)
    push!(nodesToVisit, bvh) # add the root node

    closest = nothing
    closest_t = ray.tmax # this will be used as tMax // early exits

    current_ray = Ray(
        origin=ray.origin,
        dir=ray.dir,
        tmin=ray.tmin,
        tmax=ray.tmax,
        depth=ray.depth
    )

    while !isempty(nodesToVisit)
        current_node = pop!(nodesToVisit)

        if !ray_intersection_aabb(current_node.p_min, current_node.p_max, current_ray)
            continue
        end

        # leaf: intersect shapes directly
        if isnothing(current_node.left) && isnothing(current_node.right)
            for i in current_node.first_index:current_node.last_index
                hit = ray_intersection(shapes[i], current_ray)
                if !isnothing(hit) && hit.t < closest_t
                    closest = hit
                    closest_t = hit.t

                    # update current ray with current permissible tMax:
                    # this should allow for early exits in the ray_intersection's
                    current_ray = Ray(
                        origin=ray.origin,
                        dir=ray.dir,
                        tmin=ray.tmin,
                        tmax=hit.t,
                        depth=ray.depth
                    )
                end
            end
        else
            # we cannot leverage ray direction vs split direction as we do not save the latter
            # project child centers onto the ray to determine which one to visit first
            left_child = current_node.left
            right_child = current_node.right

            if !isnothing(left_child) && !isnothing(right_child)
                # calculate approx children distance
                left_center = (left_child.p_min + left_child.p_max) * 0.5
                right_center = (right_child.p_min + right_child.p_max) * 0.5
                left_distance = (left_center - ray.origin) ⋅ ray.dir
                right_distance = (right_center - ray.origin) ⋅ ray.dir

                # remember: first in last out. so as we advance in th while loop:
                # first add farther node (it will be skipped as the current iteration will end)
                # then add closer node (it will be processed first in the next iteration)
                if left_distance < right_distance
                    push!(nodesToVisit, right_child)
                    push!(nodesToVisit, left_child)
                else
                    push!(nodesToVisit, left_child)
                    push!(nodesToVisit, right_child)
                end
            else
                if !isnothing(right_child)
                    push!(nodesToVisit, right_child)
                end
                if !isnothing(left_child)
                    push!(nodesToVisit, left_child)
                end
            end
        end
    end

    return closest
end

"""
    struct BVHShapeDebug <: AbstractShape
Shape that holds a BVH tree and the relative shapes, but will return the innermost bounding box hit.
# Fields
- `bvhroot::BVHNode`: The root node of the BVH tree.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree.
# Constructor
- `BVHShapeDebug(bvhroot::BVHNode, shapes::Vector{AbstractShape})`: Creates a new `BVHShapeDebug` with the specified BVH root and shapes.
"""
struct BVHShapeDebug <: AbstractShape
    bvhroot::BVHNode
    shapes::Vector{AbstractShape}
end

"""
    ray_intersection(bvhshape::BVHShapeDebug, ray::Ray)
Check if a ray intersects with the BVHShapeDebug `bvhshape`, returning the innermost bounding box hit.
# Arguments
- `bvhshape::BVHShapeDebug`: The BVHShapeDebug containing the BVH tree and shapes.
- `ray::Ray`: The ray to check for intersection.
# Returns
- `HitRecord` or `nothing`: A `HitRecord` if the ray intersects a shape in the BVHShapeDebug, or `nothing` if it does not. The `bvh_depth` field of the `HitRecord` will be populated.
# Note
The return value will be populated by placeholder values for `normal`, `surface_P`, and `shape` (the first shape in the BVH).
"""
function ray_intersection(bvhshape::BVHShapeDebug, ray::Ray)
    return ray_intersection_bvh_box(bvhshape.bvhroot, bvhshape.shapes, ray, 0)
end

"""
    ray_intersection_aabb_withtime(pmin::Point, pmax::Point, ray::Ray)
Check if a ray intersects with an Axis-Aligned Bounding Box (AABB) defined by `pmin` and `pmax`, and return the time of intersection.
# Arguments
- `pmin::Point`: The minimum point of the AABB.
- `pmax::Point`: The maximum point of the AABB.
- `ray::Ray`: The ray to check for intersection.
# Returns
- `(Bool, Float64)`: A tuple where the first element is `true` if the ray intersects the AABB, and the second element is the time of intersection. If there is no intersection, the first element is `false` and the second element is `Inf`.
"""
function ray_intersection_aabb_withtime(pmin::Point, pmax::Point, ray::Ray)
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
        return false, Inf
    end

    first_hit = tmin > ray.tmin ? tmin : tmax
    hit = first_hit <= ray.tmax
    return (convert(Bool, hit), convert(Float64, first_hit))
end

"""
    ray_intersection_bvh_box(bvh::BVHNode, shapes::Vector{AbstractShape}, ray::Ray, bvh_depth::Int64)
Check if a ray intersects with the BVH tree `bvh` containing the shapes in `shapes`, returning the innermost bounding box hit.
# Arguments
- `bvh::BVHNode`: The root node of the BVH tree.
- `shapes::Vector{AbstractShape}`: The vector of shapes used by the BVH Tree.
- `ray::Ray`: The ray to check for intersection.
- `bvh_depth::Int64`: The current depth of the BVH tree.
# Returns
- `HitRecord` or `nothing`: A `HitRecord` if the ray intersects a shape in the BVH, or `nothing` if it does not. The `bvh_depth` field of the `HitRecord` will be populated.
# Note
The return value will be populated by placeholder values for `normal`, `surface_P`, and `shape` (the first shape in the BVH).
"""
function ray_intersection_bvh_box(bvh::BVHNode, shapes::Vector{AbstractShape}, ray::Ray, bvh_depth::Int64)
    bvh_depth += 1
    
    hit, first_hit = ray_intersection_aabb_withtime(bvh.p_min, bvh.p_max, ray)
    #@debug "ray_intersection_bvh_boxe" hit=hit first_hit=first_hit
    if isnothing(bvh.left) && isnothing(bvh.right) && hit
        return HitRecord(
            world_P = ray.origin + ray.dir * first_hit,
            normal = Normal(1.0, 0.0, 0.0), # placeholder normal
            surface_P = SurfacePoint(0.0, 0.0), # placeholder surface point
            ray = ray,
            shape = shapes[bvh.first_index], # placeholder shape
            t = first_hit,
            bvh_depth=bvh_depth,
        )
    end

    if !hit
        return nothing
    end

    left_hit = !isnothing(bvh.left) ? ray_intersection_bvh_box(bvh.left, shapes, ray, bvh_depth) : nothing
    right_hit = !isnothing(bvh.right) ? ray_intersection_bvh_box(bvh.right, shapes, ray, bvh_depth) : nothing

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