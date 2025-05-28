#---------------------------------------------------------
# SourceLocation
#---------------------------------------------------------

struct SourceLocation
    filename::String
    line::Int64
    col::Int64
end

#---------------------------------------------------------
# InputStream
#---------------------------------------------------------

mutable struct InputStream
    stream::IOBuffer
    location::SourceLocation
    saved_c::Char
    saved_loc::SourceLocation
    tablature::Int

    function InputStream(stream::IOBuffer, file_name = "", tablature = 8)
        loc = SourceLocation(file_name, 1, 1)
        new(stream, loc, "", loc, tablature)
    end
end

#---------------------------------------------------------
# Token
#---------------------------------------------------------

struct Token

end