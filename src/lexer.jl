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

"""
    Base.:(==)(a::SourceLocation, b::SourceLocation)

Compares two `SourceLocation` objects for equality.
# Arguments
- `a::SourceLocation`: First source location to compare.
- `b::SourceLocation`: Second source location to compare.
# Returns
- `Bool`: `true` if both locations have the same filename, line, and column; `false` otherwise.
"""
function Base.:(==)(a::SourceLocation, b::SourceLocation)
    return a.filename == b.filename && a.line == b.line && a.col == b.col
end

#---------------------------------------------------------
# Consts and Enums and alikes
#---------------------------------------------------------

const WHITESPACE = [' ', '\t', '\n', '\r']

const SYMBOLS = ['(', ')', '[', ']', '<', '>', ',', '*'] #Add here if some missing

@enum KeywordEnum begin
    FLOAT
    UNIFORM
    CHECKERED
    IMAGE
    MATERIAL
    DIFFUSE
    SPECULAR
    IDENTITY
    TRANSLATION
    ROTATION_X
    ROTATION_Y
    ROTATION_Z
    SCALING
    CAMERA
    ORTHOGONAL
    PERSPECTIVE
    POINTLIGHT
    SPOTLIGHT
    SPHERE
    BOX
    CYLINDER
    CONE
    MESH
    PLANE
    CIRCLE
    RECTANGLE
    TRIANGLE
    PARALLELOGRAM

    ADD #to add shapes and lights to the world
    #CSG
    UNION
    INTERSECTION
    DIFFERENCE
end

const KEYWORDS = Dict(
    "float" => FLOAT,
    "uniform" => UNIFORM,
    "checkered" => CHECKERED,
    "image" => IMAGE,
    "material" => MATERIAL,
    "diffuse" => DIFFUSE,
    "specular" => SPECULAR,
    "identity" => IDENTITY,
    "translation" => TRANSLATION,
    "rotation_x" => ROTATION_X,
    "rotation_y" => ROTATION_Y,
    "rotation_z" => ROTATION_Z,
    "scaling" => SCALING,
    "camera" => CAMERA,
    "orthogonal" => ORTHOGONAL,
    "perspective" => PERSPECTIVE,
    "pointlight" => POINTLIGHT,
    "spotlight" => SPOTLIGHT,
    "sphere" => SPHERE,
    "box" => BOX,
    "cylinder" => CYLINDER,
    "cone" => CONE,
    "mesh" => MESH,
    "plane" => PLANE,
    "circle" => CIRCLE,
    "rectangle" => RECTANGLE,
    "triangle" => TRIANGLE,
    "parallelogram" => PARALLELOGRAM,

    "add" => ADD,
    #CSG
    "union" => UNION,
    "intersection" => INTERSECTION,
    "difference" => DIFFERENCE
)

#---------------------------------------------------------
# Token
#---------------------------------------------------------

abstract type AbstractToken end


"""
    IdentifierToken(location::SourceLocation, identifier::String)

A token representing an identifier (variable, function, etc.) in the source code.
"""
struct IdentifierToken <: AbstractToken
    location::SourceLocation
    identifier::String

    function IdentifierToken(location::SourceLocation, id::String)
        new(location, id)
    end
end


"""
    StringToken(location::SourceLocation, s::String)

A token representing a literal string in the source code.
"""
struct StringToken <: AbstractToken
    location::SourceLocation
    string::String

    function StringToken(location::SourceLocation, s::String)
        new(location, s)
    end
end


"""
    NumberToken(location::SourceLocation, value::Float64)

A token representing a numeric literal in the source code.
"""
struct NumberToken <: AbstractToken
    location::SourceLocation
    value::Float64

    function NumberToken(location::SourceLocation, value::Float64)
        new(location, value)
    end
end

"""
    SymbolToken(location::SourceLocation, symbol::Char)

A token representing a single character symbol in the source code.
"""
struct SymbolToken <: AbstractToken
    location::SourceLocation
    symbol::Char

    function SymbolToken(location::SourceLocation, symbol::Char)
        new(location, symbol)
    end
end


"""
    KeywordToken(location::SourceLocation, keyword::KeywordEnum)

A token representing a keyword in the source code.
"""
struct KeywordToken <: AbstractToken
    location::SourceLocation
    keyword::KeywordEnum

    function KeywordToken(location::SourceLocation, keyword::KeywordEnum)
        new(location, keyword)
    end
end


""" 
    StopToken(location::SourceLocation)

A special token that indicates the end of the file.
"""
struct StopToken <: AbstractToken
    location::SourceLocation

end

#functions for comparing Tokens (useful for testing)
"""
    Base.:(==)(a::IdentifierToken, b::IdentifierToken)

Compares two `IdentifierToken` objects for equality.
# Arguments
- `a::IdentifierToken`: First identifier token to compare.
- `b::IdentifierToken`: Second identifier token to compare.
# Returns
- `Bool`: `true` if both tokens have the same location and identifier; `false` otherwise.
"""
function Base.:(==)(a::IdentifierToken, b::IdentifierToken)
    return a.location == b.location && a.identifier == b.identifier
end

"""
    Base.:(==)(a::StringToken, b::StringToken)

Compares two `StringToken` objects for equality.
# Arguments
- `a::StringToken`: First string token to compare.
- `b::StringToken`: Second string token to compare.
# Returns
- `Bool`: `true` if both tokens have the same location and string value; `false` otherwise.
"""
function Base.:(==)(a::StringToken, b::StringToken)
    return a.location == b.location && a.string == b.string
end

"""
    Base.:(==)(a::NumberToken, b::NumberToken)

Compares two `NumberToken` objects for equality.
# Arguments
- `a::NumberToken`: First number token to compare.
- `b::NumberToken`: Second number token to compare.
# Returns
- `Bool`: `true` if both tokens have the same location and numeric value; `false` otherwise.
"""
function Base.:(==)(a::NumberToken, b::NumberToken)
    return a.location == b.location && a.value == b.value
end

"""
    Base.:(==)(a::SymbolToken, b::SymbolToken)

Compares two `SymbolToken` objects for equality.
# Arguments
- `a::SymbolToken`: First symbol token to compare.
- `b::SymbolToken`: Second symbol token to compare.
# Returns
- `Bool`: `true` if both tokens have the same location and symbol; `false` otherwise.
"""
function Base.:(==)(a::SymbolToken, b::SymbolToken)
    return a.location == b.location && a.symbol == b.symbol
end

"""
    Base.:(==)(a::KeywordToken, b::KeywordToken)

Compares two `KeywordToken` objects for equality.
# Arguments
- `a::KeywordToken`: First keyword token to compare.
- `b::KeywordToken`: Second keyword token to compare.
# Returns
- `Bool`: `true` if both tokens have the same location and keyword; `false` otherwise.
"""
function Base.:(==)(a::KeywordToken, b::KeywordToken)
    return a.location == b.location && a.keyword == b.keyword
end

"""
    Base.:(==)(a::StopToken, b::StopToken)

Compares two `StopToken` objects for equality.
# Arguments
- `a::StopToken`: First stop token to compare.
- `b::StopToken`: Second stop token to compare.
# Returns
- `Bool`: `true` if both tokens have the same location; `false` otherwise.
"""
function Base.:(==)(a::StopToken, b::StopToken)
    return a.location == b.location
end


#---------------------------------------------------------
# InputStream
#---------------------------------------------------------

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
    saved_token::Union{AbstractToken,Nothing}

    function InputStream(stream::IOBuffer, file_name="", tablature=8)
        loc = SourceLocation(file_name, 1, 1)
        new(stream, loc, '\0', loc, tablature, nothing)
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
    _read_char(input::InputStream)
Reads a character from the `InputStream`, handling saved characters and updating the position.
# Arguments
- `input::InputStream`: The input stream from which to read the character.
# Returns
- `Char`: The character read from the input stream. If the end of the stream is reached, returns `'\0'`.
"""
function _read_char(input::InputStream)
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
    _unread_char!(input::InputStream, ch::Char)
Pushes a character back to the `InputStream`, allowing it to be read again later.
# Arguments
- `input::InputStream`: The input stream to which the character should be pushed back.
- `ch::Char`: The character to push back to the stream.
# Throws
- `InputStreamError`: If there is already a saved character in the input stream, indicating that it cannot unread another character.
"""
function _unread_char!(input::InputStream, ch::Char)
    # Push a character back to the stream
    if input.saved_c != '\0' # Cannot unread if there is already a saved character
        throw(InputStreamError("cannot unread: `saved_c` is not empty", input))
    end
    input.saved_c = ch
    input.location = SourceLocation(input.saved_loc)
end

"""
    _skip_whitespaces_and_comments!(input::InputStream)
Skips over whitespace characters and comments in the `InputStream`.
# Arguments
- `input::InputStream`: The input stream from which to skip whitespace and comments.
"""
function _skip_whitespaces_and_comments!(input::InputStream)
    ch = _read_char(input)
    while ch in WHITESPACE || ch == '#'
        if ch == '#'
            # It's a comment! Keep reading until the end of the line
            # (include the case '\0', the end-of-file)
            while true
                comment_ch = _read_char(input)
                if comment_ch in ['\r', '\n', '\0']
                    break
                end
            end
        end

        ch = _read_char(input)
        if ch == '\0'
            return
        end
    end

    # Put the non-whitespace character back
    _unread_char!(input, ch)
end


#---------------------------------------------------------
# Reading Tokens
#---------------------------------------------------------
"""
    struct GrammarError <: Exception

Represents an error that occurs during parsing due to invalid grammar in the source code.
# Fields
- `location::SourceLocation`: The location in the source code where the grammar error occurred.
- `msg::String`: A message describing the grammar error.
"""
struct GrammarError <: Exception
    location::SourceLocation
    msg::String
end

"""
    Base.showerror(io::IO, err::GrammarError)

Customizes how `GrammarError` exceptions are displayed, showing the error location and message.
# Arguments
- `io::IO`: The IO stream to which the error message should be written.
- `err::GrammarError`: The grammar error to display.
"""
# Personalization
function Base.showerror(io::IO, err::GrammarError)
    print(io, "GrammarError at ", err.location, ": ", err.msg)
end

""" 
    _parse_string_token(input::InputStream)
Parses a string token from the `InputStream`, reading characters until a closing quote is found.
# Arguments
- `input::InputStream`: The input stream from which to read the string token.
- `token_location::SourceLocation`: The location in the source file where the string token starts.
# Returns
- `StringToken`: A `StringToken` object containing the parsed string and its location.
# Throws
- `GrammarError`: If the string is not properly terminated (i.e., no closing quote found before the end of the file).
"""
function _parse_string_token(input::InputStream, token_location::SourceLocation)
    token = ""
    while true
        ch = _read_char(input)
        if ch == '\0'
            # End of file reached before closing quote
            throw(GrammarError(token_location, "Unterminated string"))
        elseif ch == '"'
            # Closing quote found, return the string token
            return StringToken(token_location, token)
        else
            # Accumulate characters in the string
            token *= ch
        end
    end
end

"""
    _parse_float_token(input::InputStream, first_char::Char, token_location::SourceLocation)

Parses a floating-point number token from the `InputStream`, starting with the given first character.
# Arguments
- `input::InputStream`: The input stream from which to read the number token.
- `first_char::Char`: The first character of the number, which has already been read.
- `token_location::SourceLocation`: The location in the source file where the number token starts.
# Returns
- `NumberToken`: A `NumberToken` object containing the parsed floating-point value and its location.
# Throws
- `GrammarError`: If the token cannot be parsed as a valid floating-point number.
"""
function _parse_float_token(input::InputStream, first_char::Char, token_location::SourceLocation)
    # Parse a number token from the input stream
    token = first_char
    while true
        ch = _read_char(input)
        if !(isdigit(ch) || ch == '.' || ch in ['e', 'E'])
            _unread_char!(input, ch)
            break
        end
        token *= ch
    end

    try
        value = parse(Float64, string(token))
        #value = isa(token, String) ? parse(Float64, token) : parse(Float64, string(token))
        return NumberToken(token_location, value)
    catch e
        show(e)
        # If parsing fails, throw a GrammarError with the current location
        throw(GrammarError(token_location, "Invalid floating-point number: $token"))
    end
end

"""
    _parse_keyword_or_identifier_token(input::InputStream, first_char::Char, token_location::SourceLocation)

Parses a keyword or identifier token from the `InputStream`, starting with the given first character.
# Arguments
- `input::InputStream`: The input stream from which to read the keyword or identifier token.
- `first_char::Char`: The first character of the token, which has already been read.
- `token_location::SourceLocation`: The location in the source file where the token starts.
# Returns
- `KeywordToken`: If the token matches a predefined keyword.
- `IdentifierToken`: If the token does not match any predefined keyword.
# Throws
- `GrammarError`: If the identifier starts with a number, which is invalid.
"""
function _parse_keyword_or_identifier_token(input::InputStream, first_char::Char, token_location::SourceLocation)
    token = first_char
    if isdigit(first_char)
        throw(GrammarError(token_location, "Identifiers cannot start with a number: $first_char"))
    end

    while true
        ch = _read_char(input)
        if !(isletter(ch) || isdigit(ch) || ch == '_')
            _unread_char!(input, ch)
            break
        end
        token *= ch
    end

    try
        return KeywordToken(token_location, KEYWORDS[token])
    catch KeyError
        return IdentifierToken(token_location, token)
    end
end

"""
    read_token(input::InputStream)::AbstractToken

Reads a token from the `InputStream` and returns it.
# Arguments
- `input::InputStream`: The input stream from which to read the token.
# Returns
- `AbstractToken`: The next token from the input stream. This could be an `IdentifierToken`, `StringToken`, `NumberToken`, `SymbolToken`, `KeywordToken`, or `StopToken`.
# Throws
- `GrammarError`: If an invalid character or token format is encountered.
"""
function _read_token(input::InputStream)

    if input.saved_token !== nothing
        # Return the saved token if it exists
        token = input.saved_token
        input.saved_token = nothing
        return token
    end

    _skip_whitespaces_and_comments!(input)

    ch = _read_char(input)
    if ch == '\0'
        # End of file reached, return a StopToken
        return StopToken(input.saved_loc)
    end

    if ch in SYMBOLS
        # One-character symbol, like '(' or ','
        return SymbolToken(input.saved_loc, ch)

    elseif ch == '"'
        #StrinkToken
        return _parse_string_token(input, input.saved_loc)

    elseif isdigit(ch) || ch in ['+', '-', '.']
        # NumberToken
        return _parse_float_token(input, ch, input.saved_loc)

    elseif isletter(ch) || ch == '_'
        #Since it begins with an alphabetic character, it must either be a keyword or a identifier
        return _parse_keyword_or_identifier_token(input, ch, input.saved_loc)
    else
        throw(GrammarError(input.saved_loc, "Invalid character $ch"))
    end
end

"""
    _unread_token!(input::InputStream, token::AbstractToken)
Unreads a token by saving it in the `InputStream`, allowing it to be read again later.
# Arguments
- `input::InputStream`: The input stream to which the token should be unread.
- `token::AbstractToken`: The token to unread.
# Throws
- `InputStreamError`: If there is already a saved token in the input stream, indicating that it cannot unread another token.
"""
function _unread_token!(input::InputStream, token::AbstractToken)
    # Unread a token by saving it in the input stream
    if input.saved_token !== nothing
        throw(InputStreamError("Cannot unread: `saved_token` is not empty", input))
    end
    input.saved_token = token
    input.saved_loc = token.location
end


