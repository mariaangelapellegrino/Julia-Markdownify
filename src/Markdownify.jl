module Markdownify

using PyCall
#using regex

export markdownify
export strip
export MarkdownifyOptions

bs4 = pyimport_conda("bs4", "Conda")
re = pyimport_conda("re", "Conda")
six = pyimport_conda("six", "Conda")

heading_re = r"convert_h[0-9]+"
# occursin(heading_re, "convert_h5") # test

#line_beginning_re = re.compile(r'^', re.MULTILINE)
#TODO

tag_re = r"[<.+?>]"
whitespace_re = r"[\r\n\s\t ]+"

FRAGMENT_ID = "__MARKDOWNIFY_WRAPPER__"
function wrap(html)
    return "<div id="*FRAGMENT_ID*">"*html*"</div>"
end
#wrap("<p>ciao<\\p>")

# Heading styles
HEADING_STYLES = ["atx", "atx_closed", "underlined"]

escaping = Dict("_" => r"\_")

function escape_char(c)
    print(escaping["_"])
    return get(escaping, c, c)
end
function escape(text)
    #return join([escape_char(c) for c in text])
    return replace(text, "_" => r"\_")
end
#escaped_string = escape("ciao_ciao")

#TODO enum tag
struct MarkdownifyOptions
    strip::Union{Vector{String},Nothing}
    convert::Union{Vector{String},Nothing}
    autolinks::Bool
    heading_style::String
    bullets::String
end
actual_options = nothing

function checkOptions(options::Union{MarkdownifyOptions,Nothing})
    if options != nothing
        if options.strip!=nothing && options.convert!=nothing
            throw("You may specify either tags to strip or tags to convert, but not both.")
        elseif !(actual_options.heading_style in HEADING_STYLES)
            throw("The specified heading style is not valid. ")
        else
            global actual_options = options
        end
    else
        global actual_options = MarkdownifyOptions(nothing, nothing, true, "underlined", "*+-")
    end
end

function convert(html::String)
    bs4 = pyimport_conda("bs4", "Conda")

    html = wrap(html)
    soup = bs4.BeautifulSoup(html, "html.parser")
    process_tag(soup.find(id=FRAGMENT_ID), true)
end

function manage_heading(attr)
    # Handle headings
    #m = occursin(heading_re,attr)
    re = pyimport_conda("re", "Conda")

    m = match(r"^h(?<n>\d)", attr)
    if m != nothing
        n = m[:n]

        #function convert_tag(el, text)
        #    convert_hn(n, el, text)
        #end

        #convert_tag.__name__ = "convert_h"*n
        #setattr(convert_tag.__name__, convert_tag)
        return "convert_hn"
    end
end

function should_convert_tag(tag)
    tag = lowercase(tag)
    strip = actual_options.strip
    convert = actual_options.convert
    if strip != nothing
        return !(tag in strip)
    elseif convert != nothing
        return tag in convert
    else
        return true
    end
end

function indent(text::String, level::Integer)
    if isempty(text)
        return ""
    end
    return replace(text, r"^" => "\t"^level)
end

function underline(text::AbstractString, pad_char::AbstractString)
    text = rstrip(text)
    if isempty(text)
        return ""
    end

    return text*"\n"*(pad_char^length(text))*"\n\n"
end

function convert_a(el, text)
    href = el.get("href")
    title = el.get("title")
    if actual_options.autolinks && text==href && title==nothing
        # Shortcut syntax
        return "<"*href*">"
    end

    if title == nothing
        title_part = ""
    else
        replace(title, '"' => r"\"")
        title_part = title
    end

    return "["*text*"]("*href*title_part*")"
end

function convert_b(el, text)
    return convert_strong(el, text)
end

function convert_blockquote(el, text)
    #'\n' + line_beginning_re.sub('> ', text) if text else ''
    if text == nothing
        return "\n"*""
    else
        return "\n"*replace(text, r"^" => "> ")
    end
end

function convert_br(el, text)
    return "  \n"
end

function convert_em(el, text)
    if text == nothing
        return ""
    else
        return "*"*text*"*"
    end
end

function convert_hn(el, text)
    m = match(r"^h(?<n>\d)", el.name)
    n = parse(Int8, m[:n])

    style = actual_options.heading_style
    text = rstrip(text)
    if style == "underlined" && n <= 2
        if n == 1
            line = "="
        else
            line = "-"
        end
        return underline(text, line)
    end

    hashes = "#"^n
    if style == "atx_closed"
        return hashes*" "*text*" "*hashes*"\n\n"
    end
    return hashes*" "*text*"\n\n"
end

function convert_i(el, text)
    return convert_em(el, text)
end

function convert_list(el, text)
    nested = false
    while el!=nothing
        if el.name == "li"
            nested = true
            break
        end
        el = el.parent
    end
    if nested
        text = "\n"*indent(text, 1)
    end
    return text
end
convert_ul = convert_list
convert_ol = convert_list

function convert_li(el, text)
    parent = el.parent
    if parent !=nothing && parent.name == "ol"
        bullet = string(parent.index(el) + 1)*"."
    else
        depth = -1
        while el != nothing
            if el.name == "ul"
                depth += 1
            end
            el = el.parent
        end

        bullets = actual_options.bullets
        bullet = bullets[depth % length(bullets)+1]
    end
    return bullet*" "*text*"\n"
end

function convert_p(el, text)
    if text == nothing
        return ""
    else
        return text*"\n\n"
    end
end

function convert_span(el, text)
    if text == nothing
        return ""
    else
        return text
    end
end

function convert_strong(el, text)
    if text == nothing
        return ""
    else
        return "**"*text*"**"
    end
end

function convert_img(el, text)
    if haskey(el.attrs, "alt")
        alt = el.attrs["alt"]
    else
        alt = ""
    end

    if haskey(el.attrs, "src")
        src = el.attrs["src"]
    else
        src = ""
    end

    if haskey(el.attrs, "title")
        title = el.attrs["title"]
        title_part = " '"*replace(title, '"' => r"\"")*"'"
    else
        title = ""
        title_part = ""
    end

    return "!["*alt*"]("*src*title_part*")"
end

function process_tag(node, children_only)
    re = pyimport_conda("re", "Conda")
    six = pyimport_conda("six", "Conda")

    text = ""
    # Convert the children first
    for el in node.children
        if isa(el, String) #pybuiltin(:isinstance)(el,bs4.NavigableString)
            text *= process_text(six.text_type(el))
        else
            text *= process_tag(el, false)
        end
    end

    if !children_only
        if match(r"h[0-9]+", node.name) != nothing
            convert_fn = Symbol(manage_heading(node.name))
        else
            convert_fn = Symbol("convert_"*node.name)
        end
        if should_convert_tag(node.name)
            callable_fn = getfield(Markdownify,convert_fn)
            text = callable_fn(node, text)
        end
    end

    return text
end

function process_text(text::String)
    if text!= ""
        return escape(replace(text, r"[\r\n\s\t ]+" => " "))
    else
        return text
    end
end

function markdownify(html::String, options::Union{MarkdownifyOptions,Nothing})
    checkOptions(options)
    return convert(html)
end
#=
print(markdownify("<b><i>Hello</i></b>",nothing)=="***Hello***")

print(markdownify("<p>Hello <span>significa ciao<span></p>",nothing)=="Hello significa ciao\n\n")


print(markdownify("<blockquote>And she was like<blockquote>Hello</blockquote></blockquote>", nothing))
print(strip(markdownify("<blockquote>And she was like <blockquote>Hello</blockquote></blockquote>", nothing)) == "> And she was like \n> > Hello")
=#
test = markdownify("&amp;amp;", nothing)
end # module
