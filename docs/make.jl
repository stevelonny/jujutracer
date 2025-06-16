push!(LOAD_PATH, "../src/")
using Documenter
using jujutracer  # Replace with your actual package name

makedocs(
    sitename="jujutracer",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true",
        size_threshold=500_000
    ),
    modules=[jujutracer],
    pages=[
        "Home" => "index.md",
        "Detailed API" => "detail.md"
        # Add your other pages here
    ]
)

deploydocs(
    repo="github.com/stevelonny/jujutracer.git",
    versions=["stable" => "v^", "v#.#", "dev" => "main"]
)