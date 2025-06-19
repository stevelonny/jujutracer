push!(LOAD_PATH, "../src/")
using Documenter
using jujutracer  # Replace with your actual package name

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
        "Home" => "index.md",
        "Introdcution" => "introduction.md",
        "Usage" => Any[
            "Scene Usage" => "scene_usage.md",
            "REPL Usage" => Any[
                            "repl/repl_usage.md",
                            "repl/world.md",
                            "repl/rendering.md",
                            "repl/repl_examples.md",]
        ],
        "Detailed API" => Any[
            "API" =>"detail.md"   
        ]
        # Add your other pages here
    ]
)

deploydocs(
    repo="github.com/stevelonny/jujutracer.git",
    versions=["stable" => "v^", "v#.#", "dev" => "main"]
)