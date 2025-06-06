using Pkg
Pkg.activate(".")

#using jujutracer
using ArgParse
#= using Logging
using TerminalLoggers
using LoggingExtras

# Create a filtered logger
module_filter(log) = log._module == jujutracer || log.level > Logging.Debug
filtered_logger = EarlyFilteredLogger(module_filter, TerminalLogger(stderr, Logging.Debug))

# Set as the global logger
global_logger(filtered_logger) =#

function parse_cli()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--width", "-W"
            arg_type = Int
            default = 640
            help = "Image width"
        "--height", "-H"
            arg_type = Int
            default = 360
            help = "Image height"
        "--output", "-o"
            default = "output.png"
            help = "Output image file"
        "--pfm_output", "-p"
            default = "output.pfm"
            help = "Output PFM file"
        "--renderer", "-r"
            arg_type = String
            range_tester = s -> s in ["path_tracer", "flat", "on_off", "point"]
            default = "path_tracer"
            help = "Renderer to use (path_tracer, flat, on_off, point)"
        "--antialiasing", "-a"
            default = 2
            help = "Antialiasing level (default: 2)"
        "scene_file"
            help = "Scene file to parse"
            required = true
    end
    return parse_args(s)
end

function main()
    parsed_args = parse_cli()
    println("Parsed args:")
    for (arg,val) in parsed_args
        println("  $arg  =>  $val")
    end
end

main()