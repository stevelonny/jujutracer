push!(LOAD_PATH,"../src/")
using Documenter
using jujutracer

makedocs(
    sitename = "jujutracer",
    format = Documenter.HTML(),
    modules = [jujutracer],
    pages = [
        "Home" => "index.md",
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/stevelonny/jujutracer.git",
    devbranch = "main"
)