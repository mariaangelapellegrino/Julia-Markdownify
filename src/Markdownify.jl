"""

"""
module Markdownify

using PyCall
using Conda

const bs4 = PyNULL()
const re = PyNULL()
const six = PyNULL()

export markdownify
#export strip
export MarkdownifyOptions

function __init__()
    copy!(bs4, pyimport_conda("bs4", "beautifulsoup4", "rsmulktis"))
    copy!(re, pyimport_conda("re", "re", "conda-forge"))
    copy!(six, pyimport_conda("six", "six", "conda-forge"))
end

include("MarkdownifyOptions.jl")
include("translator.jl")

 #markdownify("<div><span>Hello</div></span>",nothing)
end # module
