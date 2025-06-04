#---------------------------------------------------------
# Meshes
#---------------------------------------------------------

struct mesh
    file::String
    shapes::Vector{Triangle}
    points::Vector{Points}
end

function read_obj_file(io::IOBuffer)
    shapes = Vector{AbstractShape}()
    points = Vector{AbstractShape}()
    
    while true
        line = split(readline(io), ' ')
        
        if line[1] == "v"
            # add a point
            ch = spli
            p = Point(parse(Float64, line[2]),
                        parse(Float64, line[3]),
                        parse(Float64, line[4]))
            push!(points, p)
        elseif line[1] == "f"
            # creo la shape
            tr = nothing
            if length(line) == 4
                tr = Triangle(points[parse(Int, line[2])],
                              points[parse(Int, line[3])],
                              points[parse(Int, line[4])])
            else
                P = Vector{Points}
                for i in 1:length(line)
                    push!(P, points[parse(Int, line[i+1])])
                end
                tr = trianglize(P)
            end
            push!(shapes, tr)
        elseif line == ""
            break
        end
    end

    return shapes, points
end

function read_obj_file(filename::String)
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