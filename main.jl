using Pkg
Pkg.activate(".")

using jujutracer

# INPUTS: PFM file to read, value of a, value of gamma, output file name
# OUTPUTS: LDR image saved in the specified file
function main()
    # Check if the correct number of arguments is provided
    if length(ARGS) != 4
        println("Usage: julia main.jl <pfm_file> <a> <gamma> <output_file>")
        return
    end

    # Parse arguments
    pfm_file = ARGS[1]
    a = parse(Float64, ARGS[2])
    gamma = parse(Float64, ARGS[3])
    output_file = ARGS[4]

    # Read the PFM image
    io = open(pfm_file, "r")
    img = read_pfm_image(io)
    close(io)

    # Apply tone mapping
    toned_img = tone_mapping(img; a=a, γ=gamma)

    # Save the LDR image
    save_ldrimage(get_matrix(toned_img), output_file)
    println("Image saved to $output_file")
end

main()
