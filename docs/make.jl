using Documenter
using Markdownify

makedocs(
    sitename = "Markdownify",
    format = :html,
    modules = [Markdownify],
    makedoc = true
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/mariaangelapellegrino/Markdownify.jl.git",
    target = "build"
)
