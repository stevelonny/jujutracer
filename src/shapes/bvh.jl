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

function centroid(t::AbstractShape)
    p1, p2 = boxed(t)
    return Point((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0, (p1.z + p2.z) / 2.0)
end

function surface_area(p1::Point, p2::Point)
    diagonal = p2 - p1
    return 2 * (diagonal.x * diagonal.y + diagonal.x * diagonal.z + diagonal.y * diagonal.z)
end

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

function SubdivideSAH!(node::BVHNode, shapes::Vector{AbstractShape}, centroids::Vector{Point}, depth::Int64; max_shapes_per_leaf::Int64=2, n_buckets::Int64=12)
    depth += 1
    # stop if there are too few shapes
    if node.last_index - node.first_index + 1 <= max_shapes_per_leaf
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

    num_shapes = node.last_index - node.first_index + 1
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
        end
        for i in node.first_index:node.last_index
            centroid_a = getfield(centroids[i], axis)
            b = floor(Int64, n_buckets * getfield(offset(centroids[i], node.p_min, node.p_max), axis)) + 1
            if b < 1
                b = 1
            elseif b > n_buckets
                b = n_buckets
            end
            if bucket_count[b] == 0
                # initialize bucket bounds
                P1, P2 = boxed(shapes[i])
                bucket_bounds[b] = (P1, P2)
            end
            bucket_count[b] += 1
            P1, P2 = boxed(shapes[i])
            bucket_bounds[b] = (
                Point(min(bucket_bounds[b][1].x, P1.x), min(bucket_bounds[b][1].y, P1.y), min(bucket_bounds[b][1].z, P1.z)),
                Point(max(bucket_bounds[b][2].x, P2.x), max(bucket_bounds[b][2].y, P2.y), max(bucket_bounds[b][2].z, P2.z))
            )
        end
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
        best_bucket = 0 #-1
        best_cost = Inf
        for i in 1:n_splits
            if costs[i] < best_cost
                best_cost = costs[i]
                best_bucket = i
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
        #@debug "Processing node with:" n_buckets=n_buckets p_max = node.p_max p_min = node.p_min axis = axis best_bucket = best_bucket best_cost = best_cost leaf_cost = leaf_cost left= node.first_index right = node.last_index
        if (best_cost < leaf_cost || num_shapes > max_shapes_per_leaf)
            # reorder shapes and centroids
            left_index = node.first_index
            right_index = node.last_index
            while left_index <= right_index
                b = floor(Int64, n_buckets * getfield(offset(centroids[left_index], node.p_min, node.p_max), axis)) + 1
                if b < 1
                    b = 1
                elseif b > n_buckets
                    b = n_buckets
                end
                if b <= best_bucket
                    left_index += 1
                else
                    if left_index < right_index
                        centroids[left_index], centroids[right_index] = centroids[right_index], centroids[left_index]
                        shapes[left_index], shapes[right_index] = shapes[right_index], shapes[left_index]
                    end
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
            UpdateBoundaries!(node.right, shapes)

            left_depth = SubdivideSAH!(node.left, shapes, centroids, depth; max_shapes_per_leaf=max_shapes_per_leaf)
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

function BuildBVH(shapes::Vector{AbstractShape}; use_sah::Bool=false, max_shapes_per_leaf::Int64=2, n_buckets::Int64=12)
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
        hit = !isnothing(closest) ? HitRecord(
            world_P=closest.world_P,
            normal=closest.normal,
            surface_P=closest.surface_P,
            t=closest.t,
            ray=closest.ray,
            shape=closest.shape,
            bvh_depth=bvh_depth
        ) : nothing
        return hit
    end

    left_hit = !isnothing(bvh.left) ? ray_intersection_bvh(bvh.left, shapes, ray, bvh_depth) : nothing
    right_hit = !isnothing(bvh.right) ? ray_intersection_bvh(bvh.right, shapes, ray, bvh_depth) : nothing

    if isnothing(left_hit) && isnothing(right_hit)
        return nothing
    elseif isnothing(left_hit)
        hit = HitRecord(
            world_P=right_hit.world_P,
            normal=right_hit.normal,
            surface_P=right_hit.surface_P,
            t=right_hit.t,
            ray=right_hit.ray,
            shape=right_hit.shape,
            bvh_depth=bvh_depth
        )
        return right_hit
    elseif isnothing(right_hit)
        hit = HitRecord(
            world_P=left_hit.world_P,
            normal=left_hit.normal,
            surface_P=left_hit.surface_P,
            t=left_hit.t,
            ray=left_hit.ray,
            shape=left_hit.shape,
            bvh_depth=bvh_depth
        )
        return left_hit
    else
        left_hit = HitRecord(
            world_P=left_hit.world_P,
            normal=left_hit.normal,
            surface_P=left_hit.surface_P,
            t=left_hit.t,
            ray=left_hit.ray,
            shape=left_hit.shape,
            bvh_depth=bvh_depth
        )
        right_hit = HitRecord(
            world_P=right_hit.world_P,
            normal=right_hit.normal,
            surface_P=right_hit.surface_P,
            t=right_hit.t,
            ray=right_hit.ray,
            shape=right_hit.shape,
            bvh_depth=bvh_depth
        )
        return left_hit.t < right_hit.t ? left_hit : right_hit
    end
end


struct BVHShape <: AbstractShape
    bvhroot::BVHNode
    shapes::Vector{AbstractShape}
end

function ray_intersection(bvhshape::BVHShape, ray::Ray)
    return ray_intersection_bvh(bvhshape.bvhroot, bvhshape.shapes, ray, 0)
end

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

