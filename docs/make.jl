push!(LOAD_PATH, "../src/")
using Documenter
using jujutracer  # Replace with your actual package name

REPL_USAGE_SUBSECTION = [
        "repl/repl_usage.md",
        "repl/world.md",
        "repl/rendering.md",
        "repl/repl_examples.md",
    ]
SCENE_USAGE_SUBSECTION = [
        "scene/scene_usage.md",
        "scene/interpreter.md",
    ]

makedocs(
    sitename="jujutracer",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true",
        size_threshold=500_000,
        collapselevel=2
    ),
    #modules=[jujutracer],
    pagesonly=true,
    pages=[
        "Home" => Any[
            "index.md",
            "introduction.md",
            ],
        "Usage" => Any[
            "Scene Usage" => SCENE_USAGE_SUBSECTION,
            "REPL Usage" => REPL_USAGE_SUBSECTION,
            ],
        # Add your other pages here
    ]
)

deploydocs(
    repo="github.com/stevelonny/jujutracer.git",
    versions=["stable" => "v^", "v#.#", "dev" => "main"]
)