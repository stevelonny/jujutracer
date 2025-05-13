#---------------------------------------------------------
# Constructive Solid Geometry
#---------------------------------------------------------
abstract type AbstractCSG <: AbstractShape end

"""
    CSGUnion(Tr::Transformation, Sh1::AbstractShape, Sh2::AbstractShape)

Return the union (\\cap ) of `Sh1`and `Sh2`
"""
struct CSGUnion <: AbstractCSG
    Tr::AbstractTransformation
    Sh1::AbstractShape
    Sh2::AbstractShape
end

"""
    CSGDifference(Tr::Transformation, Sh1::AbstractShape, Sh2::AbstractShape)

Return the difference `Sh1 - Sh2`
"""
struct CSGDifference <: AbstractCSG
    Tr::AbstractTransformation
    Sh1::AbstractShape
    Sh2::AbstractShape
end

"""
    CSGIntersection(Tr::Transformation, Sh1::AbstractShape, Sh2::AbstractShape)

Return the intersection (\\cap ) of `Sh1`and `Sh2`
"""
struct CSGIntersection <: AbstractCSG
    Tr::AbstractTransformation
    Sh1::AbstractShape
    Sh2::AbstractShape
end

Base.:∪(S1::AbstractShape, S2::AbstractShape) = CSGUnion(Transformation(), S1, S2)
Base.:-(S1::AbstractShape, S2::AbstractShape) = CSGDifference(Transformation(), S1, S2)
Base.:∩(S1::AbstractShape, S2::AbstractShape) = CSGIntersection(Transformation(), S1, S2)

"""
    ray_intersection(U::CSGUnion, ray::Ray)

Calculate the intersection of a ray and a union of shapes
# Arguments
- `U::CSGUnion` the union of shapes
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record of the shape fistly hitten if there is an intersection, nothing otherwise
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

# this function is used when we are constructing with more than one csg
function ray_intersection_list(U::CSGUnion, ray::Ray)
    # collects the hit records list of the two shapes
    HR1_list = ray_intersection_list(U.Sh1, ray)
    HR2_list = ray_intersection_list(U.Sh2, ray)

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

function internal(U::CSGUnion, P::Point)
    p = inverse(U.Tr)(P) # P in the un-transofmed union system
    return internal(U.Sh1, p) || internal(U.Sh2, p)
end

"""
    ray_intersection(U::Difference, ray::Ray)

Calculate the intersection of a ray and a difference of shapes
# Arguments
- `D::CSGDifference` the difference of shapes
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record of the shape fistly hitten if there is an intersection, nothing otherwise
"""
function ray_intersection(D::CSGDifference, ray::Ray)
    HR_list = ray_intersection_list(D, ray)
    return isnothing(HR_list) ? nothing : HR_list[1]
end

function ray_intersection_list(D::CSGDifference, ray::Ray)
    # collect the hrs of the first shape
    HR1_list = ray_intersection_list(D.Sh1, ray)

    if isnothing(HR1_list)
        return nothing
    end

    # remove hits that are not inside the second shape: correspond to points eliminated by the difference
    HR1_list = filter(x -> !internal(D.Sh2, x.world_P), HR1_list)

    # collect the hrs of the second shape
    HR2_list = ray_intersection_list(D.Sh2, ray)

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


function internal(D::CSGDifference, P::Point)
    p = inverse(D.Tr)(P) # P in the un-transofmed difference system
    return internal(D.Sh1, p) && !internal(D.Sh2, p)
end

"""
    ray_intersection(I::CSGIntersection, ray::Ray)

Calculate the intersection of a ray and a union of shapes
# Arguments
- `U::CSGIntersection` the intersection of shapes
- `ray::Ray` the ray
# Returns
- `HitRecord` the hit record of the shape fistly hitten if there is an intersection, nothing otherwise
"""
function ray_intersection(I::CSGIntersection, ray::Ray)
    HR1 = ray_intersection(I.Sh1, ray)
    HR2 = ray_intersection(I.Sh2, ray)

    if isnothing(HR1) || isnothing(HR2)
        return nothing
    elseif HR2.t > HR1.t && internal(I.Sh1, HR2.world_P)
        return HitRecord(
            world_P=HR2.world_P,
            normal=HR2.normal,
            normal2=(HR1.normal2 ⋅ ray.dir > 0.0) ? HR1.normal2 : -HR1.normal2,
            surface_P=HR2.surface_P,
            t=HR2.t,
            t2=HR1.t2,
            ray=ray
        ) # HR2 but with the exit point of Sh1
    elseif HR1.t > HR2.t && internal(I.Sh2, HR1.world_P)
        return return HitRecord(
            world_P=HR1.world_P,
            normal=HR1.normal,
            normal2=(HR2.normal2 ⋅ ray.dir > 0.0) ? HR2.normal2 : -HR2.normal2,
            surface_P=HR1.surface_P,
            t=HR1.t,
            t2=HR2.t2,
            ray=ray
        ) # HR1 but with the exit point of Sh2
    else
        return nothing
    end
end

function internal(I::CSGIntersection, P::Point)
    p = inverse(I.Tr)(P) # P in the un-transofmed intersection system
    return internal(I.Sh1, p) && internal(I.Sh2, p) # da inserire la trasformation di I
end