const PIGMENTS = [
    UNIFORM,
    CHECKERED,
    IMAGE
]

const BRDFS = [
    DIFFUSE,
    SPECULAR
]

const TRANSFORMATIONS = [
    IDENTITY,
    TRANSLATION,
    ROTATION_X,
    ROTATION_Y,
    ROTATION_Z,
    SCALING
]

const CAMERAS = [
    ORTHOGONAL,
    PERSPECTIVE
]

#-----------------------------------------------------------------------
# Scene
#------------------------------------------------------------------------
mutable struct Scene
    materials::Dict{String,Material}
    world::Union{World,Nothing}
    camera::Union{AbstractCamera,Nothing}
    float_variables::Dict{String,Float64}
    overridden_variables::Set{String}

    function Scene(;
        materials=Dict{String,Material}(),
        world=nothing,
        camera=nothing,
        float_variables=Dict{String,Float64}(),
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
function expected_number(s::InputStream, dictionary::Dict{String,Float64})
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
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `Vec`: A vector object with the parsed x, y, and z components.
"""
function parse_vector(s::InputStream, dictionary::Dict{String,Float64})
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
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `RGB`: An RGB color object with the parsed red, green, and blue components.
"""
function parse_color(s::InputStream, dictionary::Dict{String,Float64})
    expected_symbol(s, '<')
    r = expected_number(s, dictionary)
    expected_symbol(s, ',')
    g = expected_number(s, dictionary)
    expected_symbol(s, ',')
    b = expected_number(s, dictionary)
    expected_symbol(s, '>')

    return RGB(r, g, b)
end

# parse_pigment and parse_brdf will be used in parse_material
"""
    parse_pigment(s::InputStream, dictionary::Dict{String, Float64})
Parses a pigment from the input stream. The expected format is either:
- `uniform(<color>)`
- `checkered(<color1>, <color2>, <div>)`
- `image(<image_path>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `Pigment`: A pigment object representing the parsed pigment type.
"""
function parse_pigment(s::InputStream, dictionary::Dict{String,Float64})
    keyword = expected_keywords(s, PIGMENTS)

    expected_symbol(s, '(')
    result = nothing
    if keyword == UNIFORM
        color = parse_color(s, dictionary)
        result = UniformPigment(color)
    elseif keyword == CHECKERED
        color1 = parse_color(s, dictionary)
        expected_symbol(s, ',')
        color2 = parse_color(s, dictionary)
        expected_symbol(s, ',')
        # we should implement difference between expected_number and expected_integer!
        div = expected_number(s, dictionary)
        result = CheckeredPigment(convert(Int, div), convert(Int, div), color1, color2)
    elseif keyword == IMAGE
        image_path = expected_string(s)
        if !isfile(image_path)
            throw(GrammarError(s.location, "image file '$image_path' does not exist"))
        end
        image = read_pfm_image(image_path)
        result = ImagePigment(image)
    else
        throw(GrammarError(s.location, "unexpected pigment type $keyword"))
    end

    expected_symbol(s, ')')
    return result
end

"""
    parse_brdf(s::InputStream, dictionary::Dict{String, Float64})
Parses a BRDF from the input stream. The expected format is either:
- `diffuse(<pigment>)`
- `specular(<pigment>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `BRDF`: A BRDF object representing the parsed BRDF type.
"""
function parse_brdf(s::InputStream, dictionary::Dict{String,Float64})
    brdf_keyword = expected_keywords(s, BRDFS)

    expected_symbol(s, '(')
    pigment = parse_pigment(s, dictionary)
    expected_symbol(s, ')')
    if brdf_keyword == DIFFUSE
        return DiffusiveBRDF(pigment)
    elseif brdf_keyword == SPECULAR
        return SpecularBRDF(pigment)
    else
        throw(GrammarError(s.location, "unexpected BRDF type $brdf_keyword"))
    end
end

"""
    parse_material(s::InputStream, dictionary::Dict{String, Float64})
Parses a material from the input stream. The expected format is `material(<emission::pigment>, <brdf>)`.
#Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
#Returns
- `Material`: A material object with the parsed emission pigment and BRDF.
"""
function parse_material(s::InputStream, dictionary::Dict{String,Float64})
    name = expected_identifier(s)

    expected_symbol(s, '(')
    brdf = parse_brdf(s, dictionary)
    expected_symbol(s, ',')
    emission_pigment = parse_pigment(s, dictionary)
    expected_symbol(s, ')')
    return name, Material(emission_pigment, brdf)
end

"""
    parse_transformation(s::InputStream, dictionary::Dict{String, Float64})
Parses a transformation from the input stream. The expected format is:
- `identity`
- `translation(<vector>)`
- `rotation_x(<angle>)`
- `rotation_y(<angle>)`
- `rotation_z(<angle>)`
- `scaling(<vector>)`
- `*` to combine transformations.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `Transformation`: A transformation object representing the parsed transformation type.
"""
function parse_transformation(s::InputStream, dictionary::Dict{String,Float64})
    result = Transformation()

    while true
        transformation_keyword = expected_keywords(s, TRANSFORMATIONS)
        if transformation_keyword == IDENTITY
            result = result ⊙ Transformation()
        elseif transformation_keyword == TRANSLATION
            expected_symbol(s, '(')
            translation_vector = parse_vector(s, dictionary)
            expected_symbol(s, ')')
            result = result ⊙ Translation(translation_vector)
        elseif transformation_keyword == ROTATION_X
            expected_symbol(s, '(')
            angle = expected_number(s, dictionary)
            expected_symbol(s, ')')
            result = result ⊙ Rx(angle)
        elseif transformation_keyword == ROTATION_Y
            expected_symbol(s, '(')
            angle = expected_number(s, dictionary)
            expected_symbol(s, ')')
            result = result ⊙ Ry(angle)
        elseif transformation_keyword == ROTATION_Z
            expected_symbol(s, '(')
            angle = expected_number(s, dictionary)
            expected_symbol(s, ')')
            result = result ⊙ Rz(angle)
        elseif transformation_keyword == SCALING
            expected_symbol(s, '(')
            scale_vector = parse_vector(s, dictionary)
            expected_symbol(s, ')')
            result = result ⊙ Scaling(scale_vector.x, scale_vector.y, scale_vector.z)
        end

        next_token = read_token(s)
        if !(next_token isa SymbolToken && next_token.symbol == '*')
            unread_token!(s, next_token)
            break
        end

    end

    return result
end

"""
    parse_sphere(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
Parses a sphere from the input stream. The expected format is:
- `sphere(<material>, <transformation>)`
`material` must be already defined in `dict_material`.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
- `dict_material::Dict{String, Material}`: A dictionary containing material names and their definitions.
# Returns
- `Sphere`: A sphere object with the parsed material and transformation.
"""
function parse_sphere(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
    expected_symbol(s, '(')

    material_name = expected_identifier(s)
    if !(haskey(dict_material, material_name))
        throw(GrammarError(s.location, "material '$material_name' not defined"))
    end

    expected_symbol(s, ',')
    transformation = parse_transformation(s, dict_float)
    expected_symbol(s, ')')

    return Sphere(transformation, dict_material[material_name])
end


"""
    parse_plane(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
Parses a plane from the input stream. The expected format is:
- `plane(<material>, <transformation>)`
`material` must be already defined in `dict_material`.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
- `dict_material::Dict{String, Material}`: A dictionary containing material names and their definitions.
"""
function parse_plane(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
    expected_symbol(s, '(')

    material_name = expected_identifier(s)
    if !(haskey(dict_material, material_name))
        throw(GrammarError(s.location, "material '$material_name' not defined"))
    end

    expected_symbol(s, ',')
    transformation = parse_transformation(s, dict_float)
    expected_symbol(s, ')')

    return Plane(transformation, dict_material[material_name])

end

"""
    parse_camera(s::InputStream, dict_float::Dict{String,Float64})
Parses a camera from the input stream. The expected format is:
- `orthogonal(<transformation>, <aspect_ratio>)`
- `perspective(<transformation>, <aspect_ratio>, <screen_distance>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- Either `Orthogonal` or `Perspective` camera object based on the parsed type.
"""
function parse_camera(s::InputStream, dict_float::Dict{String,Float64})
    expected_symbol(s, '(')

    camera_type = expected_keywords(s, CAMERAS)
    expected_symbol(s, ',')
    transformation = parse_transformation(s, dict_float)
    expected_symbol(s, ',')
    if camera_type == ORTHOGONAL
        aspect_ratio = expected_number(s, dict_float)
        expected_symbol(s, ')')
        return Orthogonal(t=transformation, a_ratio=aspect_ratio)
    elseif camera_type == PERSPECTIVE
        aspect_ratio = expected_number(s, dict_float)
        expected_symbol(s, ',')
        screen_distance = expected_number(s, dict_float)
        expected_symbol(s, ')')
        return Perspective(d=screen_distance, t=transformation, a_ratio=aspect_ratio)
    else
        throw(GrammarError(s.location, "unexpected camera type $camera_type"))
    end

end

"""
    parse_scene(s::InputStream, variables::Dict{String,Float64}=Dict{String,Float64}())
Parses a scene from the input stream.
# Arguments
- `s::InputStream`: The input stream to read from.
- `variables::Dict{String, Float64}`: A dictionary containing variable names and their values. Defaults to an empty dictionary.
# Returns
- `Scene`: A scene object containing the parsed materials, world, camera, and float variables.
"""
function parse_scene(s::InputStream, variables::Dict{String,Float64}=Dict{String,Float64}())
    scene = Scene()
    scene.float_variables = variables
    scene.overridden_variables = Set(keys(variables))

    shapes = Vector{AbstractShape}()

    while true
        token = read_token(s)
        if token isa StopToken
            break
        end
        if !(token isa KeywordToken)
            throw(GrammarError(token.location, "expected a keyword or stop token, got $token"))
        end
        if token.keyword == FLOAT
            variable_name = expected_identifier(s)

            variable_location = s.location

            expected_symbol(s, '(')
            value = expected_number(s, scene.float_variables)
            expected_symbol(s, ')')
            
            if haskey(scene.float_variables, variable_name) && !(variable_name in scene.overridden_variables)
                throw(GrammarError(variable_location, "variable '$variable_name' already defined"))
            end

            if !(haskey(scene.float_variables, variable_name))
                scene.float_variables[variable_name] = value     
            end
        elseif token.keyword == MATERIAL
            material_name, material = parse_material(s, scene.float_variables)
            scene.materials[material_name] = material
        elseif token.keyword == SPHERE
            sphere = parse_sphere(s, scene.float_variables, scene.materials)
            push!(shapes, sphere)
        elseif token.keyword == PLANE
            plane = parse_plane(s, scene.float_variables, scene.materials)
            push!(shapes, plane)
        elseif token.keyword == CAMERA
            if !isnothing(scene.camera)
                throw(GrammarError(token.location, "camera already defined"))
            end
            scene.camera = parse_camera(s, scene.float_variables)
        else 
            throw(GrammarError(token.location, "unexpected keyword $token.keyword"))
        end
    end

    if isnothing(scene.camera)
        throw(GrammarError(s.location, "camera not defined"))
    end
    if isempty(scene.materials)
        throw(GrammarError(s.location, "no materials defined"))
    end
    if isempty(shapes)
        throw(GrammarError(s.location, "no shapes defined"))
    end
    scene.world = World(shapes)
    return scene
end
