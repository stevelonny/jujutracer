#---------------------------------------------------------
# Constructive Solid Geometry
#---------------------------------------------------------

"""
    struct CSGUnion <: AbstractSolid

Represents the union of two solid shapes.
# Fields
- `Tr::AbstractTransformation`: The transformation applied to the union.
- `Sh1::AbstractSolid`, `Sh2::AbstractSolid`: The two solid shapes being united.
# See also
- [`CSGDifference`](@ref): Represents the difference of two solid shapes.
- [`CSGIntersection`](@ref): Represents the intersection of two solid shapes.
"""
struct CSGUnion <: AbstractSolid
    Tr::AbstractTransformation
    Sh1::AbstractSolid
    Sh2::AbstractSolid
end

"""
    struct CSGDifference <: AbstractSolid

Represents the difference of two solid shapes.
# Fields
- `Tr::AbstractTransformation`: The transformation applied to the difference.
- `Sh1::AbstractSolid`, `Sh2::AbstractSolid`: The two solid shapes where `Sh1 - Sh2` is computed.
# See also
- [`CSGUnion`](@ref): Represents the union of two solid shapes.
- [`CSGIntersection`](@ref): Represents the intersection of two solid shapes.
"""
struct CSGDifference <: AbstractSolid
    Tr::AbstractTransformation
    Sh1::AbstractSolid
    Sh2::AbstractSolid
end

"""
    struct CSGIntersection <: AbstractSolid

Represents the intersection of two solid shapes.
# Fields
- `Tr::AbstractTransformation`: The transformation applied to the intersection.
- `Sh1::AbstractSolid`, `Sh2::AbstractSolid`: The two solid shapes being intersected.
# See also
- [`CSGUnion`](@ref): Represents the union of two solid shapes.
- [`CSGDifference`](@ref): Represents the difference of two solid shapes.
"""
struct CSGIntersection <: AbstractSolid
    Tr::AbstractTransformation
    Sh1::AbstractSolid
    Sh2::AbstractSolid
end

Base.:∪(S1::AbstractSolid, S2::AbstractSolid) = CSGUnion(Transformation(), S1, S2)
Base.:∪(S1::AbstractSolid, S2::AbstractShape) = throw(ArgumentError("CSGUnion only accepts AbstractSolid types."))
Base.:∪(S1::AbstractShape, S2::AbstractSolid) = throw(ArgumentError("CSGUnion only accepts AbstractSolid types."))
Base.:∪(S1::AbstractShape, S2::AbstractShape) = throw(ArgumentError("CSGUnion only accepts AbstractSolid types."))
Base.:-(S1::AbstractSolid, S2::AbstractSolid) = CSGDifference(Transformation(), S1, S2)
Base.:-(S1::AbstractSolid, S2::AbstractShape) = throw(ArgumentError("CSGDifference only accepts AbstractSolid types."))
Base.:-(S1::AbstractShape, S2::AbstractSolid) = throw(ArgumentError("CSGDifference only accepts AbstractSolid types."))
Base.:-(S1::AbstractShape, S2::AbstractShape) = throw(ArgumentError("CSGDifference only accepts AbstractSolid types."))
Base.:∩(S1::AbstractSolid, S2::AbstractSolid) = CSGIntersection(Transformation(), S1, S2)
Base.:∩(S1::AbstractSolid, S2::AbstractShape) = throw(ArgumentError("CSGIntersection only accepts AbstractSolid types."))
Base.:∩(S1::AbstractShape, S2::AbstractSolid) = throw(ArgumentError("CSGIntersection only accepts AbstractSolid types."))
Base.:∩(S1::AbstractShape, S2::AbstractShape) = throw(ArgumentError("CSGIntersection only accepts AbstractSolid types."))

"""
    ray_intersection(U::CSGUnion, ray::Ray)

Calculates the intersection of a ray with the union of two solid shapes.
# Arguments
- `U::CSGUnion`: The union of solid shapes.
- `ray::Ray`: The ray to intersect.
# Returns
- [`HitRecord`](@ref): The hit record of the first shape hit, if any.
- `nothing`: If no intersection occurs.
"""
function ray_intersection(U::CSGUnion, ray::Ray)
    HR1 = ray_intersection(U.Sh1, ray)
    HR2 = ray_intersection(U.Sh2, ray)

    if isnothing(HR1)
        if isnothing(HR2)
            return nothing
        else
            return HR2
        end
    elseif isnothing(HR2)
        return HR1
    else
        return (HR1.t < HR2.t) ? HR1 : HR2
    end
end

"""
    ray_intersection_list(U::CSGUnion, ray::Ray)

Calculates all intersections of a ray with the union of two solid shapes.
# Arguments
- `U::CSGUnion`: The union of solid shapes.
- `ray::Ray`: The ray to intersect.
# Returns
- `Vector{HitRecord}`: A sorted list of hit records for all intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(U::CSGUnion, ray::Ray)
    inv_ray = _unsafe_inverse(U.Tr)(ray) # ray in the un-transformed union system
    # collects the hit records list of the two shapes
    HR1_list = ray_intersection_list(U.Sh1, inv_ray)
    HR2_list = ray_intersection_list(U.Sh2, inv_ray)

    if isnothing(HR1_list)
        if isnothing(HR2_list)
            return nothing
        else
            return HR2_list
        end
    elseif isnothing(HR2_list)
        return HR1_list
    else
        # construct list of hits from both shapes, sort them by t
        # and return the first one
        hits = vcat(HR1_list, HR2_list)
        sort!(hits, by=x -> x.t)
        # return the first hit record
        return hits
    end
end

"""
    internal(U::CSGUnion, P::Point)

Checks if a point is inside the union of two solid shapes.
# Arguments
- `U::CSGUnion`: The union of solid shapes.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the union, `false` otherwise.
"""
function internal(U::CSGUnion, P::Point)
    p = _unsafe_inverse(U.Tr)(P) # P in the un-transofmed union system
    return internal(U.Sh1, p) || internal(U.Sh2, p)
end

"""
    ray_intersection(D::CSGDifference, ray::Ray)

Calculates the intersection of a ray with the difference of two solid shapes.
# Arguments
- `D::CSGDifference`: The difference of solid shapes.
- `ray::Ray`: The ray to intersect.
# Returns
- [`HitRecord`](@ref): The hit record of the first shape hit, if any.
- `nothing`: If no intersection occurs.
"""
function ray_intersection(D::CSGDifference, ray::Ray)
    HR_list = ray_intersection_list(D, ray)
    return isnothing(HR_list) ? nothing : HR_list[1]
end

"""
    ray_intersection_list(D::CSGDifference, ray::Ray)

Calculates all intersections of a ray with the difference of two solid shapes.
# Arguments
- `D::CSGDifference`: The difference of solid shapes.
- `ray::Ray`: The ray to intersect.
# Returns
- `Vector{HitRecord}`: A sorted list of hit records for all intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(D::CSGDifference, ray::Ray)
    inv_ray = _unsafe_inverse(D.Tr)(ray) # ray in the un-transformed difference system
    # collect the hrs of the first shape
    HR1_list = ray_intersection_list(D.Sh1, inv_ray)

    if isnothing(HR1_list)
        return nothing
    end

    # remove hits that are not inside the second shape: correspond to points eliminated by the difference
    HR1_list = filter(x -> !internal(D.Sh2, x.world_P), HR1_list)

    # collect the hrs of the second shape
    HR2_list = ray_intersection_list(D.Sh2, inv_ray)

    if !isnothing(HR2_list)
        # remove hits that are inside the first shape: conserve only internal points to the first shape
        HR2_list = filter(x -> internal(D.Sh1, x.world_P), HR2_list)
    else
        HR2_list = []
    end

    # combine the list and sort them by t (will be used to find the first hit)
    HR_list = vcat(HR1_list, HR2_list)
    return isempty(HR_list) ? nothing : sort(HR_list, by=hit -> hit.t)
end

"""
    internal(D::CSGDifference, P::Point)

Checks if a point is inside the difference of two solid shapes.
# Arguments
- `D::CSGDifference`: The difference of solid shapes.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the difference, `false` otherwise.
"""
function internal(D::CSGDifference, P::Point)
    p = _unsafe_inverse(D.Tr)(P) # P in the un-transofmed difference system
    return internal(D.Sh1, p) && !internal(D.Sh2, p)
end

"""
    ray_intersection(I::CSGIntersection, ray::Ray)

Calculates the intersection of a ray with the intersection of two solid shapes.
# Arguments
- `I::CSGIntersection`: The intersection of solid shapes.
- `ray::Ray`: The ray to intersect.
# Returns
- [`HitRecord`](@ref): The hit record of the first shape hit, if any.
- `nothing`: If no intersection occurs.
"""
function ray_intersection(I::CSGIntersection, ray::Ray)
    HR_list = ray_intersection_list(I, ray)
    return isnothing(HR_list) ? nothing : HR_list[1]
end

"""
    ray_intersection_list(I::CSGIntersection, ray::Ray)

Calculates all intersections of a ray with the intersection of two solid shapes.
# Arguments
- `I::CSGIntersection`: The intersection of solid shapes.
- `ray::Ray`: The ray to intersect.
# Returns
- `Vector{HitRecord}`: A sorted list of hit records for all intersections, ordered by distance.
- `nothing`: If no intersections occur.
"""
function ray_intersection_list(I::CSGIntersection, ray::Ray)
    inv_ray = _unsafe_inverse(I.Tr)(ray) # ray in the un-transformed intersection system
    # collect the hrs of both shapes
    HR1_list = ray_intersection_list(I.Sh1, inv_ray)
    if isnothing(HR1_list)
        return nothing
    end
    HR2_list = ray_intersection_list(I.Sh2, inv_ray)
    if isnothing(HR2_list)
        return nothing
    end
    # HR1: remove hits that are not inside the second shape: they do not belong to the intersection
    HR1_list = filter(x -> internal(I.Sh2, x.world_P), HR1_list)
    # HR2: remove hits that are not inside the first shape: they do not belong to the intersection
    HR2_list = filter(x -> internal(I.Sh1, x.world_P), HR2_list)

    HR_list = vcat(HR1_list, HR2_list)
    return isempty(HR_list) ? nothing : sort(HR_list, by=hit -> hit.t)
end

"""
    internal(I::CSGIntersection, P::Point)

Checks if a point is inside the intersection of two solid shapes.
# Arguments
- `I::CSGIntersection`: The intersection of solid shapes.
- `P::Point`: The point to check.
# Returns
- `Bool`: `true` if the point is inside the intersection, `false` otherwise.
"""
function internal(I::CSGIntersection, P::Point)
    p = _unsafe_inverse(I.Tr)(P) # P in the un-transofmed intersection system
    return internal(I.Sh1, p) && internal(I.Sh2, p) # da inserire la trasformation di I
end