"""
    PIGMENTS

A vector of all supported pigment types in the scene description language.
Used for validating pigment keywords in the parser.
"""
const PIGMENTS = [
    UNIFORM,
    CHECKERED,
    IMAGE
]

"""
    BRDFS

A vector of all supported BRDF (Bidirectional Reflectance Distribution Function) types
in the scene description language. Used for validating BRDF keywords in the parser.
"""
const BRDFS = [
    DIFFUSE,
    SPECULAR,
    REFRACTIVE
]

"""
    TRANSFORMATIONS

A vector of all supported transformation types in the scene description language.
Used for validating transformation keywords in the parser.
"""
const TRANSFORMATIONS = [
    IDENTITY,
    TRANSLATION,
    ROTATION_X,
    ROTATION_Y,
    ROTATION_Z,
    SCALING
]

"""
    CAMERAS

A vector of all supported camera types in the scene description language.
Used for validating camera keywords in the parser.
"""
const CAMERAS = [
    ORTHOGONAL,
    PERSPECTIVE
]

"""
    SHAPES

A vector of all supported shape types in the scene description language.
Used for validating shape keywords in the parser.
"""
const SHAPES = [
    SPHERE,
    BOX,
    CYLINDER,
    CONE,
    PLANE,
    CIRCLE,
    RECTANGLE
]

"""
    shapes_constructors

A dictionary mapping shape keywords to their respective constructor types.
Used to instantiate the appropriate shape object when parsing a scene description.
"""
const shapes_constructors = Dict(
    SPHERE => Sphere(),
    BOX => Box(),
    CYLINDER => Cylinder(),
    CONE => Cone(),
    PLANE => Plane(),
    CIRCLE => Circle(),
    RECTANGLE => Rectangle()
)

"""
    typeshapes

A Union type of all shape types supported in the scene description language.
Used for type annotations and dispatch to ensure proper shape handling.
"""
const typeshapes = Union{Sphere,Box,Cylinder,Cone,Plane,Circle,Rectangle}

"""
    CSG_operations
A vector of all supported Constructive Solid Geometry (CSG) operations in the scene description language.
Used for validating CSG operation keywords in the parser.
"""
const CSG = [
    UNION,
    DIFFERENCE,
    INTERSECTION
]

"""
    csg_constructors
A dictionary mapping CSG operation keywords to their respective constructor types.
Used to instantiate the appropriate CSG operation object when parsing a scene description.
"""
const csg_constructors = Dict(
    UNION => CSGUnion,
    DIFFERENCE => CSGDifference,
    INTERSECTION => CSGIntersection
)

"""
    typeCSG
A Union type of all CSG operation types supported in the scene description language.
Used for type annotations and dispatch to ensure proper CSG operation handling.
"""
const typeCSG = Union{CSGUnion, CSGDifference, CSGIntersection}


#-----------------------------------------------------------------------
# Scene
#------------------------------------------------------------------------
"""
    mutable struct Scene

Represents a complete scene to be rendered, containing materials, shapes, camera, and variables.
# Fields
- `materials::Dict{String,Material}`: A dictionary mapping material names to their definitions.
- `world::Union{World,Nothing}`: The world object containing all shapes to be rendered, or `nothing` if not set.
- `camera::Union{AbstractCamera,Nothing}`: The camera used to view the scene, or `nothing` if not set.
- `float_variables::Dict{String,Float64}`: A dictionary mapping variable names to their floating-point values.
- `overridden_variables::Set{String}`: A set of variable names that have been overridden and should not be redefined.
- `all_shapes::Dict{String, AbstractShape}`: A dictionary containing all shapes defined in the scene.
- `all_lights::Dict{String, AbstractLight}`: A dictionary containing all lights defined in the scene.
- `shapes::Vector{AbstractShape}`: A vector of shapes to be rendered, excluding lights.
- `acc_shapes::Vector{AbstractShape}`: A vector of shapes to be accelerated.
- `bvhdepth::Int64`: The depth of the BVH (Bounding Volume Hierarchy) used for acceleration.
# Constructors
- `Scene(;
    materials=Dict{String,Material}(),
    world=nothing,
    camera=nothing,
    float_variables=Dict{String,Float64}(),
    overridden_variables=Set{String}(),
    all_shapes=Dict{String, AbstractShape}(),
    all_lights=Dict{String, AbstractLight}(),
    shapes=Vector{AbstractShape}(),
    acc_shapes=Vector{AbstractShape}(),
    bvhdepth=0
)`: Creates a new scene with the specified parameters.
"""
mutable struct Scene
    materials::Dict{String,Material}
    world::Union{World,Nothing}
    camera::Union{AbstractCamera,Nothing}
    float_variables::Dict{String,Float64}
    overridden_variables::Set{String}
    all_shapes::Dict{String, AbstractShape}
    all_lights::Dict{String, AbstractLight}

    shapes::Vector{AbstractShape}
    acc_shapes::Vector{AbstractShape}
    bvhdepth::Int64

    function Scene(;
        materials=Dict{String,Material}(),
        world=nothing,
        camera=nothing,
        float_variables=Dict{String,Float64}(),
        overridden_variables=Set{String}(),
        all_shapes=Dict{String, AbstractShape}(),
        all_lights=Dict{String, AbstractLight}(),
        shapes=Vector{AbstractShape}(),
        acc_shapes=Vector{AbstractShape}(),
        bvhdepth=0
    )
        new(materials, world, camera, float_variables, overridden_variables, all_shapes, all_lights, shapes, acc_shapes, bvhdepth)
    end
end

#-----------------------------------------------------------------------
# Expected functions
#------------------------------------------------------------------------
"""
    expect_symbol(s::InputStream, symbol::Char)

Checks if the next token in the input stream matches the expected symbol.
# Arguments
- `s::InputStream`: The input stream to read from.
- `symbol::Char`: The expected symbol character.
# Returns
- `Char`: The symbol character that was read.
# Throws
- `GrammarError`: If the next token is not a symbol or if it doesn't match the expected symbol.
"""
function _expect_symbol(s::InputStream, symbol::Vararg{Char})
    token = _read_token(s)
    if !(token isa SymbolToken) || !(token.symbol in symbol)
        throw(GrammarError(token.location, "got $token instead of $symbol"))
    end

    return token.symbol
end

"""
    _expect_keywords(s::InputStream, keywords::Vector{KeywordEnum})

Checks if the next token in the input stream matches one of the expected keywords and returns it.
# Arguments
- `s::InputStream`: The input stream to read from.
- `keywords::Vector{KeywordEnum}`: A list of expected keywords.
# Returns
- `KeywordEnum`: The keyword that was read.
# Throws
- `GrammarError`: If the next token is not a keyword or if it doesn't match any of the expected keywords.
"""
function _expect_keywords(s::InputStream, keywords::Vector{KeywordEnum})
    token = _read_token(s)

    if !(token isa KeywordToken)
        throw(GrammarError(token.location, "expected a keyword instead of $token"))
    end
    if !(token.keyword in keywords)
        throw(GrammarError(token.location, "expected one of $keywords instead of $(token.keyword)"))
    end

    return token.keyword
end

"""
    _expect_number(s::InputStream, dictionary::Dict{String, Float64})

Check if the next token in the input stream is a number and returns it. If it's an identifier, looks up its value in the dictionary.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: Dictionary to look up identifier values.
# Returns
- `Float64`: The numeric value read from the input stream, either directly or from a variable lookup.
# Throws
- `GrammarError`: If the next token is not a number or a defined identifier.
"""
function _expect_number(s::InputStream, dictionary::Dict{String,Float64})
    token = _read_token(s)

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
    _expect_string(s::InputStream)

Check if the next token in the input stream is a string and returns it.
# Arguments
- `s::InputStream`: The input stream to read from.
# Returns
- `String`: The string value read from the input stream.
# Throws
- `GrammarError`: If the next token is not a string.
"""
function _expect_string(s::InputStream)
    token = _read_token(s)
    if !(token isa StringToken)
        throw(GrammarError(token.location, "got $token instead of a StringToken"))
    end
    return token.string
end

"""
    _expect_identifier(s::InputStream)

Check if the next token in the input stream is an identifier and returns it.
# Arguments
- `s::InputStream`: The input stream to read from.
# Returns
- `String`: The identifier name read from the input stream.
# Throws
- `GrammarError`: If the next token is not an identifier.
"""
function _expect_identifier(s::InputStream)
    token = _read_token(s)
    if !(token isa IdentifierToken)
        throw(GrammarError(token.location, "got $token instead of an IdentifierToken"))
    end

    return token.identifier
end

#------------------------------------------------------------------------
# parse_* functions
#------------------------------------------------------------------------

# as _expect_number we pass a dictionary instead of a Scene for testing purposes
# remember to pass the correct dict in _parse_scene

"""
    _parse_vector(s::InputStream, dictionary::Dict{String, Float64})
Parses a vector from the input stream. The expected format is `[x, y, z]`.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `Vec`: A vector object with the parsed x, y, and z components.
"""
function _parse_vector(s::InputStream, dictionary::Dict{String,Float64})
    _expect_symbol(s, '[')
    x = _expect_number(s, dictionary)
    _expect_symbol(s, ',')
    y = _expect_number(s, dictionary)
    _expect_symbol(s, ',')
    z = _expect_number(s, dictionary)
    _expect_symbol(s, ']')

    return Vec(x, y, z)
end

"""
    _parse_color(s::InputStream, dictionary::Dict{String, Float64})
Parses a color from the input stream. The expected format is `<r, g, b>`.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `RGB`: An RGB color object with the parsed red, green, and blue components.
"""
function _parse_color(s::InputStream, dictionary::Dict{String,Float64})
    _expect_symbol(s, '<')
    r = _expect_number(s, dictionary)
    _expect_symbol(s, ',')
    g = _expect_number(s, dictionary)
    _expect_symbol(s, ',')
    b = _expect_number(s, dictionary)
    _expect_symbol(s, '>')

    return RGB(r, g, b)
end

# _parse_pigment and _parse_brdf will be used in _parse_material
"""
    _parse_pigment(s::InputStream, dictionary::Dict{String, Float64})
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
function _parse_pigment(s::InputStream, dictionary::Dict{String,Float64})
    keyword = _expect_keywords(s, PIGMENTS)

    _expect_symbol(s, '(')
    result = nothing
    if keyword == UNIFORM
        color = _parse_color(s, dictionary)
        result = UniformPigment(color)
    elseif keyword == CHECKERED
        color1 = _parse_color(s, dictionary)
        _expect_symbol(s, ',')
        color2 = _parse_color(s, dictionary)
        _expect_symbol(s, ',')
        # we should implement difference between _expect_number and _expect_integer!
        div = _expect_number(s, dictionary)
        result = CheckeredPigment(convert(Int, div), convert(Int, div), color1, color2)
    elseif keyword == IMAGE
        image_path = _expect_string(s)
        if !isfile(image_path)
            throw(GrammarError(s.location, "image file '$image_path' does not exist"))
        end
        image = read_pfm_image(image_path)
        result = ImagePigment(image)
    else
        throw(GrammarError(s.location, "unexpected pigment type $keyword"))
    end

    _expect_symbol(s, ')')
    return result
end

"""
    _parse_brdf(s::InputStream, dictionary::Dict{String, Float64})
Parses a BRDF from the input stream. The expected format is either:
- `diffuse(<pigment>)`
- `specular(<pigment>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `BRDF`: A BRDF object representing the parsed BRDF type.
"""
function _parse_brdf(s::InputStream, dictionary::Dict{String,Float64})
    brdf_keyword = _expect_keywords(s, BRDFS)

    _expect_symbol(s, '(')
    pigment = _parse_pigment(s, dictionary)
    
    if brdf_keyword == DIFFUSE
        _expect_symbol(s, ')')
        return DiffusiveBRDF(pigment)
    elseif brdf_keyword == SPECULAR
        _expect_symbol(s, ')')
        return SpecularBRDF(pigment)
    elseif brdf_keyword == REFRACTIVE
        _expect_symbol(s, ',')
        value = _expect_number(s, dictionary)
        _expect_symbol(s, ')')
        return RefractiveBRDF(pigment, value)
    else
        throw(GrammarError(s.location, "unexpected BRDF type $brdf_keyword"))
    end
end

"""
    _parse_material(s::InputStream, dictionary::Dict{String, Float64})
Parses a material from the input stream. The expected format is `material(<emission::pigment>, <brdf>)`.
#Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
#Returns
- `Material`: A material object with the parsed emission pigment and BRDF.
"""
function _parse_material(s::InputStream, dictionary::Dict{String,Float64})
    name = _expect_identifier(s)

    _expect_symbol(s, '(')
    brdf = _parse_brdf(s, dictionary)
    _expect_symbol(s, ',')
    emission_pigment = _parse_pigment(s, dictionary)
    _expect_symbol(s, ')')
    return name, Material(emission_pigment, brdf)
end

"""
    _parse_transformation(s::InputStream, dictionary::Dict{String, Float64})
Parses a transformation from the input stream. The expected format is:
- `identity`
- `translation(<vector>)`
- `rotation_x(<angle>)`
- `rotation_y(<angle>)`
- `rotation_z(<angle>)`
- `scaling(<vector>)`
- `*` to combine transformations.
Angles are expected in degrees and will be converted to radians.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dictionary::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `Transformation`: A transformation object representing the parsed transformation type.
"""
function _parse_transformation(s::InputStream, dictionary::Dict{String,Float64})
    result = Transformation()

    while true
        transformation_keyword = _expect_keywords(s, TRANSFORMATIONS)
        if transformation_keyword == IDENTITY
            result = result ⊙ Transformation()
        elseif transformation_keyword == TRANSLATION
            _expect_symbol(s, '(')
            translation_vector = _parse_vector(s, dictionary)
            _expect_symbol(s, ')')
            result = result ⊙ Translation(translation_vector)
        elseif transformation_keyword == ROTATION_X
            _expect_symbol(s, '(')
            angle = _expect_number(s, dictionary)
            angle = convert(Float64, angle * (π / 180))
            _expect_symbol(s, ')')
            result = result ⊙ Rx(angle)
        elseif transformation_keyword == ROTATION_Y
            _expect_symbol(s, '(')
            angle = _expect_number(s, dictionary)
            angle = convert(Float64, angle * (π / 180))
            _expect_symbol(s, ')')
            result = result ⊙ Ry(angle)
        elseif transformation_keyword == ROTATION_Z
            _expect_symbol(s, '(')
            angle = _expect_number(s, dictionary)
            angle = convert(Float64, angle * (π / 180))
            _expect_symbol(s, ')')
            result = result ⊙ Rz(angle)
        elseif transformation_keyword == SCALING
            _expect_symbol(s, '(')
            scale_vector = _parse_vector(s, dictionary)
            _expect_symbol(s, ')')
            result = result ⊙ Scaling(scale_vector.x, scale_vector.y, scale_vector.z)
        end

        next_token = _read_token(s)
        if !(next_token isa SymbolToken && next_token.symbol == '*')
            _unread_token!(s, next_token)
            break
        end

    end

    return result
end


"""
    _parse_shape(shape::T, s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material}) where {T <: typeshapes}
Parses a shape from the input stream. The expected format is:
- `sphere(<material_name>, <transformation>)`
- `box(<material_name>, <transformation>)`
- `cylinder(<material_name>, <transformation>)`
- `cone(<material_name>, <transformation>)`
- `plane(<material_name>, <transformation>)`
- `circle(<material_name>, <transformation>)`
- `rectangle(<material_name>, <transformation>)`
# Arguments
- `shape::T`: The type of shape to parse, which must be one of the defined shape types. See [`typeshapes`](@ref), [`shapes_constructors`](@ref) and [`SHAPES`](@ref).
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
- `dict_material::Dict{String, Material}`: A dictionary containing material names and their definitions.
# Returns
- `shape_name::String`: The name of the shape as defined in the input.
- `T`: An instance of the specified shape type with the parsed transformation and material.
# Throws
- `GrammarError`: If the input does not match the expected format or if a material is not defined.
"""
function _parse_shape(shape::T, s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material}) where {T<:typeshapes}
    shape_name = _expect_identifier(s)
    _expect_symbol(s, '(')

    material_name = _expect_identifier(s)
    if !(haskey(dict_material, material_name))
        throw(GrammarError(s.location, "material '$material_name' not defined"))
    end

    _expect_symbol(s, ',')
    transformation = _parse_transformation(s, dict_float)
    _expect_symbol(s, ')')
    return shape_name, T(transformation, dict_material[material_name])
end

"""
    _parse_triangle(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
Parses a triangle from the input stream. The expected format is:
- `triangle(<material_name>, <v1>, <v2>, <v3>)`
# Arguments
- `s::InputStream`: The input stream to read from.
"""
function _parse_triangle(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
    name = _expect_identifier(s)
    _expect_symbol(s, '(')

    material_name = _expect_identifier(s)
    if !(haskey(dict_material, material_name))
        throw(GrammarError(s.location, "material '$material_name' not defined"))
    end

    _expect_symbol(s, ',')
    v1 = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    v2 = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    v3 = _parse_vector(s, dict_float)
    _expect_symbol(s, ')')

    return name , Triangle(Point(v1), Point(v2), Point(v3), dict_material[material_name])
end

"""
    _parse_parallelogram(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
Parses a parallelogram from the input stream. The expected format is:
- `parallelogram(<material_name>, <v1>, <v2>, <v3>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
- `dict_material::Dict{String, Material}`: A dictionary containing material names and their definitions.
# Returns
- `name::String`: The name of the parallelogram as defined in the input.
- `Parallelogram`: A parallelogram object with the parsed vertices and material.
# Throws
- `GrammarError`: If the input does not match the expected format or if a material is not defined.
"""
function _parse_parallelogram(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
    name = _expect_identifier(s)
    _expect_symbol(s, '(')

    material_name = _expect_identifier(s)
    if !(haskey(dict_material, material_name))
        throw(GrammarError(s.location, "material '$material_name' not defined"))
    end

    _expect_symbol(s, ',')
    v1 = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    v2 = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    v3 = _parse_vector(s, dict_float)
    _expect_symbol(s, ')')

    return name, Parallelogram(Point(v1), Point(v2), Point(v3), dict_material[material_name])
end


"""
    _parse_camera(s::InputStream, dict_float::Dict{String,Float64})
Parses a camera from the input stream. The expected format is:
- `orthogonal(<transformation>, <aspect_ratio>)`
- `perspective(<transformation>, <aspect_ratio>, <screen_distance>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- Either `Orthogonal` or `Perspective` camera object based on the parsed type.
"""
function _parse_camera(s::InputStream, dict_float::Dict{String,Float64})
    _expect_symbol(s, '(')

    camera_type = _expect_keywords(s, CAMERAS)
    _expect_symbol(s, ',')
    transformation = _parse_transformation(s, dict_float)
    _expect_symbol(s, ',')
    if camera_type == ORTHOGONAL
        aspect_ratio = _expect_number(s, dict_float)
        _expect_symbol(s, ')')
        return Orthogonal(t=transformation, a_ratio=aspect_ratio)
    elseif camera_type == PERSPECTIVE
        aspect_ratio = _expect_number(s, dict_float)
        _expect_symbol(s, ',')
        screen_distance = _expect_number(s, dict_float)
        _expect_symbol(s, ')')
        return Perspective(d=screen_distance, t=transformation, a_ratio=aspect_ratio)
    else
        throw(GrammarError(s.location, "unexpected camera type $camera_type"))
    end

end

"""
    _parse_pointlight(s::InputStream, dict_float::Dict{String,Float64})
Parses a point light source from the input stream. The expected format is:
- `pointlight(<position>, <color>, <scale>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `LightSource`: A point light source object with the parsed position, color, and scale.
"""
function _parse_lightsource(s::InputStream, dict_float::Dict{String,Float64})
    name = _expect_identifier(s)
    _expect_symbol(s, '(')

    position = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    color = _parse_color(s, dict_float)
    _expect_symbol(s, ',')
    scale = _expect_number(s, dict_float)
    _expect_symbol(s, ')')

    return name, LightSource(Point(position), color, scale)
end

"""
    _parse_spotlight(s::InputStream, dict_float::Dict{String,Float64})
Parses a spotlight source from the input stream. The expected format is:
- `spotlight(<position>, <direction>, <color>, <scale>, <total_angle>, <falloff_angle>)`
Angles are expected in degrees and will be converted to radians.
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
# Returns
- `SpotLight`: A spotlight object with the parsed position, direction, color, scale, and cosine/angles values.
"""
function _parse_spotlight(s::InputStream, dict_float::Dict{String,Float64})
    name = _expect_identifier(s)
    _expect_symbol(s, '(')

    position = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    direction = _parse_vector(s, dict_float)
    _expect_symbol(s, ',')
    color = _parse_color(s, dict_float)
    _expect_symbol(s, ',')
    scale = _expect_number(s, dict_float)
    _expect_symbol(s, ',')
    angle = _expect_number(s, dict_float)
    cos_total = cos(angle * (π / 180))
    _expect_symbol(s, ',')
    angle = _expect_number(s, dict_float)
    cos_falloff = cos(angle * (π / 180))
    _expect_symbol(s, ')')

    return name, SpotLight(Point(position), direction, color, scale, cos_total, cos_falloff)
end

"""
    _parse_CSG_operation(s::InputStream, all_shapes::Dict{String, AbstractShape}, T::Type{<:typeCSG})

Parses a Constructive Solid Geometry (CSG) operation from the input stream. The expected format is:
- `union name(<transformation>, <shape1>, <shape2>)`
- `difference name(<transformation>, <shape1>, <shape2>)`
- `intersection name(<transformation>, <shape1>, <shape2>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `all_shapes::Dict{String, AbstractShape}`: A dictionary containing all defined shapes.
- `dict_float::Dict{String,Float64}`: A dictionary containing variable names and their values. 
- `T::Type{<:typeCSG}`: The type of CSG operation to parse, which must be one of the defined CSG types. See [`typeCSG`](@ref) and [`csg_constructors`](@ref).
# Returns
- `Tuple{String, T}`: A tuple containing the name of the CSG operation and the constructed CSG shape.
"""
function _parse_CSG_operation(s::InputStream, all_shapes::Dict{String, AbstractShape}, dict_float::Dict{String,Float64}, T::Type{<:typeCSG})
    csg_name = _expect_identifier(s)
    _expect_symbol(s, '(')

    transformation = _parse_transformation(s, dict_float)
    _expect_symbol(s, ',')

    shape1_name = _expect_identifier(s)
    if !(haskey(all_shapes, shape1_name))
        throw(GrammarError(s.location, "shape '$shape1_name' not defined"))
    end
    
    _expect_symbol(s, ',')
    shape2_name = _expect_identifier(s)
    if !(haskey(all_shapes, shape2_name))
        throw(GrammarError(s.location, "shape '$shape2_name' not defined"))
    end
    
    _expect_symbol(s, ')')
    shape = T(transformation, all_shapes[shape1_name] , all_shapes[shape2_name])
    #=
    while true
        symbol= _expect_symbol(s, ',', ')')

        if symbol == ')'
            break
        end

        shape_name = _expect_identifier(s)
        if !(haskey(all_shapes, shape_name))
            throw(GrammarError(s.location, "shape '$shape_name' not defined"))
        end

        shape = T(Transformation(),shape , all_shapes[shape_name])
    end
    =#
    return csg_name , shape
end

"""
    _parse_mesh(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
Parses a mesh from the input stream. The expected format is:
`mesh(<filename>, <material_name>, <transformation>, <order>)`
# Arguments
- `s::InputStream`: The input stream to read from.
- `dict_float::Dict{String, Float64}`: A dictionary containing variable names and their values.
- `dict_material::Dict{String, Material}`: A dictionary containing material names and their definitions.
# Returns
- `Tuple{String, mesh}`: A tuple containing the name of the mesh and the constructed mesh object.
"""
function _parse_mesh(s::InputStream, dict_float::Dict{String,Float64}, dict_material::Dict{String,Material})
    name = _expect_identifier(s)
    _expect_symbol(s, '(')

    material_name = _expect_identifier(s)
    if !(haskey(dict_material, material_name))
        throw(GrammarError(s.location, "material '$material_name' not defined"))
    end
    _expect_symbol(s, ',')
    transformation = _parse_transformation(s, dict_float)
    
    _expect_symbol(s, ',')
    filename = _expect_string(s)
    _expect_symbol(s, ',')
    order = _expect_string(s)
    _expect_symbol(s, ')')

    m_mesh = mesh(filename, transformation, dict_material[material_name]; order=order)

    return name, m_mesh
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

    lights = Vector{AbstractLight}()

    while true
        token = _read_token(s)
        if token isa StopToken
            break
        end
        if !(token isa KeywordToken)
            throw(GrammarError(token.location, "expected a keyword or stop token, got $token"))
        end
        if token.keyword == FLOAT
            variable_name = _expect_identifier(s)

            variable_location = s.location

            _expect_symbol(s, '(')
            value = _expect_number(s, scene.float_variables)
            _expect_symbol(s, ')')

            if haskey(scene.float_variables, variable_name) && !(variable_name in scene.overridden_variables)
                throw(GrammarError(variable_location, "variable '$variable_name' already defined"))
            end

            if !(haskey(scene.float_variables, variable_name))
                scene.float_variables[variable_name] = value
            end
        elseif token.keyword == MATERIAL
            material_name, material = _parse_material(s, scene.float_variables)
            scene.materials[material_name] = material
        elseif haskey(shapes_constructors, token.keyword)
            shape_constructor = shapes_constructors[token.keyword]
            shape_name, shape = _parse_shape(shape_constructor, s, scene.float_variables, scene.materials)
            scene.all_shapes[shape_name] = shape
        elseif token.keyword == TRIANGLE
            name, triangle = _parse_triangle(s, scene.float_variables, scene.materials)
            scene.all_shapes[name] = triangle
        elseif token.keyword == PARALLELOGRAM
            name , parallelogram = _parse_parallelogram(s, scene.float_variables, scene.materials)
            scene.all_shapes[name] = parallelogram
        elseif token.keyword == POINTLIGHT
            name, light_source = _parse_lightsource(s, scene.float_variables)
            scene.all_lights[name] = light_source
        elseif token.keyword == SPOTLIGHT
            name, spot_light = _parse_spotlight(s, scene.float_variables)
            scene.all_lights[name] = spot_light
        elseif token.keyword == CAMERA
            if !isnothing(scene.camera)
                throw(GrammarError(token.location, "camera already defined"))
            end
            scene.camera = _parse_camera(s, scene.float_variables)
        elseif haskey(csg_constructors, token.keyword)
            csg_constructor = csg_constructors[token.keyword]
            name, shape = _parse_CSG_operation(s, scene.all_shapes, scene.float_variables, csg_constructor)
            scene.all_shapes[name] = shape
        elseif token.keyword == MESH
            name, m_mesh = _parse_mesh(s, scene.float_variables, scene.materials)
            scene.all_shapes[name] = m_mesh
        elseif token.keyword == ADD
            name = _expect_identifier(s)
            if haskey(scene.all_shapes, name)
                # if it is a CSG shape, box them
                if scene.all_shapes[name] isa Union{CSGUnion, CSGDifference, CSGIntersection}
                    boxedcsg = AABB(scene.all_shapes[name])
                    push!(scene.shapes, boxedcsg)
                elseif scene.all_shapes[name] isa jujutracer.mesh
                    push!(scene.shapes, scene.all_shapes[name])
                    for t in scene.all_shapes[name].shapes
                        push!(scene.acc_shapes, t)
                    end
                else
                    push!(scene.shapes, scene.all_shapes[name])
                end
            elseif haskey(scene.all_lights, name)
                push!(lights, scene.all_lights[name])
            else
                throw(GrammarError(token.location, "no shape or light with name '$name' defined"))
            end
        else
            throw(GrammarError(token.location, "unexpected keyword $token.keyword"))
        end
    end

    #shapes = collect(values(scene.all_shapes))

    if isnothing(scene.camera)
        throw(GrammarError(s.location, "camera not defined"))
    end
    if isempty(scene.materials)
        throw(GrammarError(s.location, "no materials defined"))
    end
    if isempty(scene.shapes)
        throw(GrammarError(s.location, "no shapes defined"))
    end

    if !isempty(scene.acc_shapes)
        bvh, scene.bvhdepth = BuildBVH!(scene.acc_shapes; use_sah=true)    
        bvhshape = BVHShape(bvh, scene.acc_shapes)
        shapes = vcat(filter(x -> !(x isa mesh), scene.shapes), bvhshape)
        scene.world = World(shapes, lights)
    else
        scene.world = World(scene.shapes, lights)
    end

    return scene
end
