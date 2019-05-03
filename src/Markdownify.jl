module Markdownify

using PyCall
using Conda

const bs4 = PyNULL()
const re = PyNULL()
const six = PyNULL()

export markdownify
export strip
export MarkdownifyOptions

#bs4 = pyimport_conda("bs4", "bs4")
#re = pyimport_conda("re", "re")
#six = pyimport_conda("six", "six")

function __init__()
    copy!(bs4, pyimport_conda("bs4", "beautifulsoup4", "rsmulktis"))
    copy!(re, pyimport_conda("re", "re", "conda-forge"))
    copy!(six, pyimport_conda("six", "six", "conda-forge"))
end

# Heading styles
HEADING_STYLES = ["atx", "atx_closed", "underlined"]

struct MarkdownifyOptions
    strip::Union{Vector{String},Nothing}
    convert::Union{Vector{String},Nothing}
    autolinks::Bool
    heading_style::String
    bullets::String
end

include("translator.jl")

test = markdownify("&amp;amp;", nothing)
end # module
