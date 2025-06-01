#---------------------------------------------------------
# SourceLocation
#---------------------------------------------------------

mutable struct SourceLocation
    filename::String
    line::Int64
    col::Int64
    function SourceLocation(location::SourceLocation)
        new(location.filename, location.line, location.col)
    end
    function SourceLocation(filename::String, line::Int64, col::Int64)
        new(filename, line, col)
    end
end

#---------------------------------------------------------
# InputStream
#---------------------------------------------------------

const WHITESPACE = [' ', '\t', '\n', '\r']

mutable struct InputStream
    stream::IOBuffer
    location::SourceLocation
    saved_c::Char
    saved_loc::SourceLocation
    tablature::Int64

    function InputStream(stream::IOBuffer, file_name="", tablature=8)
        loc = SourceLocation(file_name, 1, 1)
        new(stream, loc, '\0', loc, tablature)
    end
end

struct InputStreamError <: Exception
    error_message::String
    input::InputStream
    function InputStreamError(error_message::String, input::InputStream)
        @debug """InputStreamError: $error_message
        location: $(input.location.filename):$(input.location.line):$(input.location.col)
        saved character: '$(input.saved_c)'
        saved location: $(input.saved_loc.filename):$(input.saved_loc.line):$(input.saved_loc.col)
        tablature: $(input.tablature)
        """
        new(error_message, input)
    end
end

function open_InputStream(filename::String, tablature=8)
    io = IOBuffer()
    open(filename, "r") do file
        write(io, file)
    end
    seekstart(io)
    return InputStream(io, filename, tablature)
end

function _update_pos!(input::InputStream, ch::Char)
    # Update `location` after having read `ch` from the stream
    if ch == '\0'
        # Nothing to do!
        return
    elseif ch == '\n'
        input.location.line += 1
        input.location.col = 1
    elseif ch == '\t'
        input.location.col += input.tablature
    else
        input.location.col += 1
    end
end

function read_char(input::InputStream)
    # Read a new character from the stream
    if input.saved_c != '\0'
        # Recover the unread character and return it
        ch = input.saved_c
        input.saved_c = '\0'
    else
        # Read a new character from the stream
        if eof(input.stream)
            ch = '\0'  # End of file
        else
            ch = read(input.stream, Char)
        end
    end

    # Save current location before updating so we can look ahead
    input.saved_loc = SourceLocation(input.location)
    _update_pos!(input, ch)

    return ch
end

function unread_char!(input::InputStream, ch::Char)
    # Push a character back to the stream
    if input.saved_c != '\0' # Cannot unread if there is already a saved character
        throw(InputStreamError("cannot unread: `saved_c` is not empty", input))
    end
    input.saved_c = ch
    input.location = SourceLocation(input.saved_loc)
end

function skip_whitespaces_and_comments!(input::InputStream)
    ch = read_char(input)
    while ch in WHITESPACE || ch == '#'
        if ch == '#'
            # It's a comment! Keep reading until the end of the line
            # (include the case '\0', the end-of-file)
            while true
                comment_ch = read_char(input)
                if comment_ch in ['\r', '\n', '\0']
                    break
                end
            end
        end

        ch = read_char(input)
        if ch == '\0'
            return
        end
    end

    # Put the non-whitespace character back
    unread_char!(input, ch)
end

#---------------------------------------------------------
# Token
#---------------------------------------------------------

struct Token

end