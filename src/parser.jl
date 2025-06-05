mutable struct Scene
    materials::Dict{String, Material}
    world::World
    camera::Union{AbstractCamera, Nothing}
    float_variables::Dict{String, Float64}
    overridden_variables::Set{String}

    function Scene(; 
        materials=Dict{String, Material}(),
        world=World(),
        camera=nothing,
        float_variables=Dict{String, Float64}(),
        overridden_variables=Set{String}()
    )
        new(materials, world, camera, float_variables, overridden_variables)
    end
end

#-----------------------------------------------------------------------
# Expected functions
#------------------------------------------------------------------------
"""
    expected_symbol(s::InputStream, symbol::Char)

Checks if the next token in the input stream matches the expected symbol.
"""
function expected_symbol(s::InputStream, symbol::Char)
    token = read_token(s)
    if !(token isa SymbolToken) || token.symbol != symbol
        throw(GrammarError(token.location, "got $token instead of $symbol"))
    end

    return token.symbol
end
 
"""
    expected_keywords(s::InputStream, keywords::Vector{KeywordEnum})

Checks if the next token in the input stream matches one of the expected keywords and returns it.
"""
function expected_keywords(s::InputStream, keywords::Vector{KeywordEnum})
    token = read_token(s)

    if !(token isa KeywordToken)
        throw(GrammarError(token.location, "expected a keyword instead of $token"))
    end
    if !(token.keyword in keywords)
        throw(GrammarError(token.location, "expected one of $keywords instead of $(token.keyword)"))
    end

    return token.keyword
end

"""
    expected_number(s::InputStream, dictionary::Dict{String, Float64})

Check if the next token in the input stream is a number and returns it.
"""
function expected_number(s::InputStream, dictionary::Dict{String, Float64})
    token = read_token(s)
    
    if token isa NumberToken
        return token.value
    
    elseif token isa IdentifierToken
        variable_name = token.identifier
        if !(haskey(dictionary, variable_name))
            throw(GrammarError(token.location, "variable '$variable_name' not defined"))
        end

        value = dictionary[variable_name]    
        return value
    end

    throw(GrammarError(token.location, "got $token instead of a number"))
end

"""
    expected_string(s::InputStream)

Check if the next token in the input stream is a string and returns it.
"""
function expected_string(s::InputStream)
    token = read_token(s)
    if !(token isa StringToken)
        throw(GrammarError(token.location, "got $token instead of a StringToken"))
    end
    return token.string
end

"""
    expected_identifier(s::InputStream)

Check if the next token in the input stream is an identifier and returns it.
"""
function expected_identifier(s::InputStream)
    token = read_token(s)
    if !(token isa IdentifierToken)
        throw(GrammarError(token.location, "got $token instead of an IdentifierToken"))
    end 

    return token.identifier
end

#------------------------------------------------------------------------
# parse_* functions
#------------------------------------------------------------------------

# as expected_number we pass a dictionary instead of a Scene for testing purposes
# remember to pass the correct dict in parse_scene

"""
    parse_vector(s::InputStream, dictionary::Dict{String, Float64})
Parses a vector from the input stream. The expected format is `[x, y, z]`.
#Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
#Returns
- `Vec`: A vector object with the parsed x, y, and z components.
"""
function parse_vector(s::InputStream, dictionary::Dict{String, Float64})
    expected_symbol(s, '[')
    x = expected_number(s, dictionary)
    expected_symbol(s, ',')
    y = expected_number(s, dictionary)
    expected_symbol(s, ',')
    z = expected_number(s, dictionary)
    expected_symbol(s, ']')

    return Vec(x, y, z)
end

"""
    parse_color(s::InputStream, dictionary::Dict{String, Float64})
Parses a color from the input stream. The expected format is `<r, g, b>`.
#Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
#Returns
- `RGB`: An RGB color object with the parsed red, green, and blue components.
"""
function parse_color(s::InputStream, dictionary::Dict{String, Float64})
    expected_symbol(s, '<')
    r = expected_number(s, dictionary)
    expected_symbol(s, ',')
    g = expected_number(s, dictionary)
    expected_symbol(s, ',')
    b = expected_number(s, dictionary)
    expected_symbol(s, '>')

    return RGB(r, g, b)
end

