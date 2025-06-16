#---------------------------------------------------------
# Meshes
#---------------------------------------------------------
"""
    struct mesh <: AbstractShape

mesh.
# Fields
- `file::String`: the source `file.obj` of the mesh
- `shape::Vector{Triangle}`: the triangles of the mesh
- `points::Vector{Point}`: the vertices of the triangles of the shape

# Constructor
- `mesh(shapes::Vector{Triangle})`: creates a mesh frome the `Vector{Triangle}`
- `mesh(file::String)`: creates a mesh from `file`
- `mesh(file::String, Tr::AbstractTransformation)`: creates a mesh from `file` with a transformation `Tr` 
- `mesh(file::String, Mat::Material)`: creates a mesh with `Mat` material from `file`
- `mesh(file::String, Tr::AbstractTransformation, Mat::Material)`: creates a mesh with `Tr` transformation and a `Mat` material.
"""
struct mesh <: AbstractShape
    file::String
    shapes::Vector{Triangle}
    points::Vector{Point}

    function mesh(shapes::Vector{Triangle})
        new("file.obj", shapes, Vector{Point}())
    end
    function mesh(file::String; order = "dwh")
        sh, p = read_obj_file(file; order)
        new(file, sh, p)
    end

    function mesh(file::String, Tr::AbstractTransformation; order = "dwh")
        sh, p = read_obj_file(file, Tr = Tr; order)
        new(file, sh, p)
    end

    function mesh(file::String, Mat::Material; order = "dwh")
        sh, p = read_obj_file(file, Mat = Mat; order)
        new(file, sh, p)
    end

    function mesh(file::String, Tr::AbstractTransformation, Mat::Material; order = "dwh")
        sh, p = read_obj_file(file, Tr = Tr, Mat = Mat; order)
        new(file, sh, p)
    end
end

"""
    trianglize(P::Vector{Points}, Tr::AbstractTransformation, Mat::Material)

Triangulation method, working only with ordered verteces
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
"""

    read_obj_file(io::IOBuffer; Tr::AbstractTransformation = Transformation(), Mat::Material = Material(); order = "dwh")

Method for constructing vectors and points from a buffer
# Fields
- `io::IOBuffer`: the buffer
- `Tr::AbstractTransformation`: an hypotetical transformation to be applied to all the shapes and points
- `Mat::Material`: an hypotetical material to be applied to all the triangles
# Keywords
- `order::String`: the order of the coordinates in the file, default is "dwh" (depth, width, height).
# Returns
- `shape::Vector{Triangle}`
- `points:Vector{Points}`
"""
function read_obj_file(io::IOBuffer; Tr::AbstractTransformation = Transformation(), Mat::Material = Material())
    shapes = Vector{Triangle}()
    points = Vector{Point}()
    faces = Vector{Vector{Int}}()
    total = io.size
    x, y, z = 1, 2, 3
    for i in eachindex(order)
        if order[i] == 'd'
            x = i
        end
        if order[i] == 'w'
            y = i
        end
        if order[i] == 'h'
            z = i
        end
    end
    @debug "Reading OBJ file from IOBuffer with size: $(total) bytes" total=total
        while !eof(io)
            line = split(readline(io), ' ')
            dim = length(line)

            if line[1] == "v"
                # add a point
                # account for empty spaces
                coord = Vector{SubString{String}}()
                for i in 2:dim
                    try
                        parse(Float64, line[i])
                        push!(coord, line[i])
                    catch
                    end
                end
                p = Point(parse(Float64, coord[x]),
                            parse(Float64, coord[y]),
                            parse(Float64, coord[z]))
                push!(points, p)
            elseif line[1] == "f"
                # possible formats:
                # f 1 2 3 ...
                # f 1/1 2/2 3/3 ...
                # f 1/1/1 2/2/2 3/3/3 ...
                # f 1//1 2//2 3//3 ...
                # face/texture/normal
                face = Vector{Int}()
                for i in 2:dim
                    face_index = split(line[i], '/')
                    push!(face, parse.(Int, face_index[1]))
                end
                push!(faces, face)
            end #if/else
        end #while
    # Convert faces to triangles
    for face in faces
        if length(face) == 3
            tr = Triangle(Tr,
                          points[face[1]],
                          points[face[2]],
                          points[face[3]],
                          Mat)
            push!(shapes, tr)
        elseif length(face) > 3
            P = Vector{Point}()
            for i in eachindex(face)
                push!(P, points[face[i]])
            end
            tr = jujutracer.trianglize(P, Tr, Mat)
            append!(shapes, tr)
        else
            throw(ArgumentError("Invalid polygon declaration"))
        end
    end
    @info "Read OBJ file: $(length(shapes)) shapes and $(length(points)) points."
    return shapes, points
end
"""

    read_obj_file(io::IOBuffer; Tr::AbstractTransformation = Transformation(), Mat::Material = Material(); order = "dwh")

Method for constructing vectors and points from a file
# Fields
- `filename::String`: the name of the `file.obj`
- `Tr::AbstractTransformation`: an hypotetical transformation to be applied to all the shapes and points
- `Mat::Material`: an hypotetical material to be applied to all the triangles
# Keywords
- `order::String`: the order of the coordinates in the file, default is "dwh" (depth, width, height).
# Returns
- `shape::Vector{Triangle}`
- `points:Vector{Points}`
"""
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
    return read_obj_file(io, Tr = Tr, Mat = Mat; order)
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