#---------------------------------------------------------
# SourceLocation
#---------------------------------------------------------

"""
    mutable struct SourceLocation
Represents a location in a source file, including the filename, line number, and column number.
# Fields
- `filename::String`: The name of the source file.
- `line::Int64`: The line number in the source file.
- `col::Int64`: The column number in the source file.
# Constructors
- `SourceLocation(location::SourceLocation)`: Creates a new `SourceLocation` from an existing one.
- `SourceLocation(filename::String, line::Int64, col::Int64)`: Creates a new `SourceLocation` with the specified filename, line, and column.
"""
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

"""
    mutable struct InputStream
Represents an input stream for reading characters from a source file, with tracking of the current position and saved character.
# Fields
- `stream::IOBuffer`: The underlying IO buffer for reading characters.
- `location::SourceLocation`: The current location in the source file.
- `saved_c::Char`: A character that has been read but not yet processed.
- `saved_loc::SourceLocation`: The location corresponding to the saved character.
- `tablature::Int64`: The number of spaces a tab character represents.
# Constructors
- `InputStream(stream::IOBuffer, file_name="", tablature=8)`: Creates a new `InputStream` with the specified IO buffer, filename, and tablature.
"""
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

"""
    struct InputStreamError <: Exception
Represents an error that occurs while reading from an `InputStream`.
# Fields
- `error_message::String`: A message describing the error.
- `input::InputStream`: The `InputStream` where the error occurred.
# Constructors
- `InputStreamError(error_message::String, input::InputStream)`: Creates a new `InputStreamError` with the specified error message and input stream. Outpus a debug message with details about the InputStream.
"""
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

"""
    open_InputStream(filename::String, tablature=8)
Opens a file and returns an `InputStream` for reading characters from it.
# Arguments
- `filename::String`: The name of the file to open.
- `tablature=8`: The number of spaces a tab character represents (default is 8).
# Returns
- `InputStream`: An `InputStream` object for reading characters from the specified file.
"""
function open_InputStream(filename::String, tablature=8)
    io = IOBuffer()
    open(filename, "r") do file
        write(io, file)
    end
    seekstart(io)
    return InputStream(io, filename, tablature)
end

"""
    _update_pos!(input::InputStream, ch::Char)
Updates the current position in the `InputStream` based on the character read.
# Arguments
- `input::InputStream`: The input stream whose position is to be updated.
- `ch::Char`: The character that was read from the stream.
"""
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

"""
    read_char(input::InputStream)
Reads a character from the `InputStream`, handling saved characters and updating the position.
# Arguments
- `input::InputStream`: The input stream from which to read the character.
# Returns
- `Char`: The character read from the input stream. If the end of the stream is reached, returns `'\0'`.
"""
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

"""
    unread_char!(input::InputStream, ch::Char)
Pushes a character back to the `InputStream`, allowing it to be read again later.
# Arguments
- `input::InputStream`: The input stream to which the character should be pushed back.
- `ch::Char`: The character to push back to the stream.
# Throws
- `InputStreamError`: If there is already a saved character in the input stream, indicating that it cannot unread another character.
"""
function unread_char!(input::InputStream, ch::Char)
    # Push a character back to the stream
    if input.saved_c != '\0' # Cannot unread if there is already a saved character
        throw(InputStreamError("cannot unread: `saved_c` is not empty", input))
    end
    input.saved_c = ch
    input.location = SourceLocation(input.saved_loc)
end

"""
    skip_whitespaces_and_comments!(input::InputStream)
Skips over whitespace characters and comments in the `InputStream`.
# Arguments
- `input::InputStream`: The input stream from which to skip whitespace and comments.
"""
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