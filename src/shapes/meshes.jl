#---------------------------------------------------------
# Meshes
#---------------------------------------------------------

struct mesh <: AbstractShape
    file::String
    shapes::Vector{Triangle}
    points::Vector{Point}

    function mesh(file::String, shapes::Vector{Trinagle}, points::Vector{Point})
        new(file, shapes, points)
    end
end

"""
    trianglize(P::Vector{Points}, Tr::AbstractTransformation, Mat::Material)
    
Works only convex poygons
"""
function trianglize(P::Vector{Points}, Tr::AbstractTransformation, Mat::Material)
    tr = Vector{Triangle}
    p = P[1]
    sort!(P, by=x -> squared_norm(x - p))
    for i in 2:(length(P) - 2)
        add = Triangle(Tr, p, P[i+1], P[i+2], Mat)
        push!(tr, add)
    end
    return tr
end

function read_obj_file(io::IOBuffer; Tr::AbstractTransformation = Transformation(), Mat::Material = Material())
    shapes = Vector{AbstractShape}()
    points = Vector{AbstractShape}()
    
    while !eof(io)
        line = split(readline(io), ' ')
        
        if line[1] == "v"
            # add a point
            p = Point(parse(Float64, line[2]),
                        parse(Float64, line[3]),
                        parse(Float64, line[4]))
            push!(points, p)
        elseif line[1] == "f"
            # add a shape
            tr = nothing
            if length(line) == 4
                tr = Triangle(Tr,
                              points[parse(Int, line[2])],
                              points[parse(Int, line[3])],
                              points[parse(Int, line[4])],
                              Mat)
            else
                P = Vector{Points}
                for i in 1:length(line)
                    push!(P, points[parse(Int, line[i+1])])
                end
                tr = trianglize(P, Tr, Mat)
            end
            push!(shapes, tr)
        end
    end

    return shapes, points
end

function read_obj_file(filename::String; Tr::AbstractTransformation = Transformation(), Mat::Material = Material())
    # Check if the file extension is valid
    if !(endswith(filename, ".obj"))
        throw(InvalidPfmFileFormat("Invalid file extension. Only .obj is supported."))
    end
    io = IOBuffer()
    @info("Reading OBJ file from file: $(abspath(filename))")
    open(filename, "r") do file
        write(io, file)
    end
    seekstart(io)
    return read_obj_file(io)
end

function mesh(file::String)
    sh, p = read_obj_file(file)
    return mesh(file, sh, p)
end

function mesh(file::String, Tr::AbstractTransformation)
    sh, p = read_obj_file(file, Tr = Tr)
    return mesh(file, sh, p)
end

function mesh(file::String, Mat::Material)
    sh, p = read_obj_file(file, Mat = Mat)
    return mesh(file, sh, p)
end

function mesh(file::String, Tr::AbstractTransformation, Mat::Material)
    sh, p = read_obj_file(file, Tr = Tr, Mat = Mat)
    return mesh(file, sh, p)
end