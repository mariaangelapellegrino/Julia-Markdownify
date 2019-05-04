"""
    MarkdownifyOptions

It models Markdownify options in order to customize the markdown in output.

**Arguments**
* `strip` : vector of tags to ignore or nothing
* `convert` : vector of tags to convert or nothing
* `autolinks` : boolean to determine the tag a conversion
* `heading_style` : parameter to customize the heading style
* `bullets` : list of symbols in order to customize the nested list conversion

**Constructors**
It is possible to specify all the parameters or use the default for all of them.
Default parameters are:
* `strip` : empty vector
* `convert` : empty vector
* `autolinks` : true
* `heading_style` : underlined
* `bullets` : *+-

"""

struct MarkdownifyOptions
    strip::Union{Vector{AbstractString},Nothing}
    convert::Union{Vector{AbstractString},Nothing}
    autolinks::Bool
    heading_style::AbstractString
    bullets::AbstractString

    MarkdownifyOptions(strip, convert, autolinks, heading_style, bullets) =
        new(strip, convert, autolinks, heading_style, bullets)
end
MarkdownifyOptions() = MarkdownifyOptions(nothing, nothing, true, "underlined", "*+-")
#=
function MarkdownifyOptions(strip::Union{Vector{AbstractString},Nothing}, convert::Union{Vector{AbstractString},Nothing}, autolinks::Bool, heading_style::AbstractString, bullets::AbstractString)
    MarkdownifyOptions(strip, nothing, true, "underlined", "*+-")
end
MarkdownifyOptions(strip::Union{Vector{AbstractString},Nothing}) = new(strip, nothing, true, "underlined", "*+-")
MarkdownifyOptions(convert::Union{Vector{AbstractString},Nothing}) = new(nothing, convert, true, "underlined", "*+-")
MarkdownifyOptions(autolinks::Bool) = new(nothing, nothing, autolinks, "underlined", "*+-")
MarkdownifyOptions(heading_style::AbstractString) = new(nothing, nothing, true, heading_style, "*+-")
MarkdownifyOptions(bullets::AbstractString) = new(nothing, nothing, true, "underlined", bullets)
MarkdownifyOptions() = new(nothing, nothing, true, "underlined", "*+-")
=#
