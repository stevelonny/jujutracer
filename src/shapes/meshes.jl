#---------------------------------------------------------
# Meshes
#---------------------------------------------------------

struct mesh <: AbstractShape
    file::String
    shapes::Vector{Triangle}
    points::Vector{Point}

    function mesh(file::String, shapes::Vector{Triangle}, points::Vector{Point})
        new(file, shapes, points)
    end
    function mesh(file::String)
        sh, p = read_obj_file(file)
        new(file, sh, p)
    end

    function mesh(file::String, Tr::AbstractTransformation)
        sh, p = read_obj_file(file, Tr = Tr)
        new(file, sh, p)
    end

    function mesh(file::String, Mat::Material)
        sh, p = read_obj_file(file, Mat = Mat)
        new(file, sh, p)
    end

    function mesh(file::String, Tr::AbstractTransformation, Mat::Material)
        sh, p = read_obj_file(file, Tr = Tr, Mat = Mat)
        new(file, sh, p)
    end
end

"""
    trianglize(P::Vector{Points}, Tr::AbstractTransformation, Mat::Material)

Works only convex poygons
"""
function trianglize(P::Vector{Point}, Tr::AbstractTransformation, Mat::Material)
    tr = Vector{Triangle}()
    p = P[1]
    #sort!(P, by=x -> norm(x - p))
    for i in 2:(length(P) - 1)
        add = Triangle(Tr, p, P[i], P[i+1], Mat)
        push!(tr, add)
    end
    return tr
end

function read_obj_file(io::IOBuffer; Tr::AbstractTransformation = Transformation(), Mat::Material = Material())
    shapes = Vector{Triangle}()
    points = Vector{Point}()
    total = io.size
    @debug "Reading OBJ file from IOBuffer with size: $(total) bytes" total=total
    @withprogress name = "Reading OBJ file" begin
        while !eof(io)
            line = split(readline(io), ' ')
            dim = length(line)
            
            if line[1] == "v"
                # add a point
                p = Point(parse(Float64, line[4]),
                            parse(Float64, line[2]),
                            parse(Float64, line[3]))
                push!(points, p)
            elseif line[1] == "f"
                # add a shape
                if dim == 4
                    tr = Triangle(Tr,
                                points[parse(Int, line[2])],
                                points[parse(Int, line[3])],
                                points[parse(Int, line[4])],
                                Mat)
                    push!(shapes, tr)
                elseif dim > 4
                    P = Vector{Point}()
                    for i in 2:dim
                        push!(P, points[parse(Int, line[i])])
                    end
                    tr = trianglize(P, Tr, Mat)
                    shapes = vcat(shapes, tr)
                else
                    throw(ArgumentError("Invalid polygon declaration"))
                end
            end #if/else
            @logprogress progress = position(io) / total
        end #while
    end #withprogress
    @info "Read OBJ file: $(length(shapes)) shapes and $(length(points)) points."
    return shapes, points
end

function read_obj_file(filename::String; Tr::AbstractTransformation = Transformation(), Mat::Material = Material())
    # Check if the file extension is valid
    if !(endswith(filename, ".obj"))
        throw(InvalidFileFormat("Invalid file extension. Only .obj is supported."))
    end
    io = IOBuffer()
    @info("Reading OBJ file from file: $(abspath(filename))")
    open(filename, "r") do file
        write(io, file)
    end
    seekstart(io)
    return read_obj_file(io, Tr = Tr, Mat = Mat)
end

function ray_intersection(S::mesh, ray::Ray)
    dim = length(S.shapes)
        closest = nothing
        for i in 1:dim
            inter = ray_intersection(S.shapes[i], ray)
            if isnothing(inter)
                continue
            end
            if (isnothing(closest) || inter.t < closest.t)
                closest = inter
            end
        end
    return closest
end

"""
    boxed(m::mesh)

Returns the two points defining the axis-aligned bounding box (AABB) that contains the mesh.
# Arguments
- `m::mesh`: the mesh to be boxed.
# Returns
- `Tuple{Point, Point}`: a tuple containing the two points defining the AABB, where the first point is the minimum corner and the second point is the maximum corner.
"""
function boxed(m::mesh)::Tuple{Point,Point}
    P1 = Point(Inf, Inf, Inf)
    P2 = Point(-Inf, -Inf, -Inf)
    for s in m.shapes
        p1, p2 = boxed(s)
        P1 = Point(min(P1.x, p1.x), min(P1.y, p1.y), min(P1.z, p1.z))
        P2 = Point(max(P2.x, p2.x), max(P2.y, p2.y), max(P2.z, p2.z))
    end
    return P1, P2
end