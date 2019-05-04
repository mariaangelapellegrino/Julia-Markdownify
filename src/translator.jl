heading_re = r"convert_h[0-9]+"
tag_re = r"[<.+?>]"
whitespace_re = r"[\r\n\s\t ]+"

HEADING_STYLES = ["atx", "atx_closed", "underlined"]
FRAGMENT_ID = "__MARKDOWNIFY_WRAPPER__"
"""
    wrap(html::AbstractString)

It wraps the hmtl provided as input into a div and returns it.
"""
function wrap(html::AbstractString)
    return "<div id="*FRAGMENT_ID*">"*html*"</div>"
end

escaping = Dict("_" => r"\_")

#=function escape_char(c)
    print(escaping["_"])
    return get(escaping, c, c)
end
=#
function escape(text)
    #return join([escape_char(c) for c in text])
    return replace(text, "_" => "\\_")
end

actual_options = nothing
"""
    checkOptions(options::Union{MarkdownifyOptions,Nothing})
If a MarkdownifyOptions is provided
    it checks if the parameters are correctly set,
otherwise it sets a default options.
"""
function checkOptions(options::Union{MarkdownifyOptions,Nothing})
    if options != nothing
        if options.strip!=nothing && options.convert!=nothing
            throw(Exception("You may specify either tags to strip or tags to convert, but not both."))
        elseif !(options.heading_style in HEADING_STYLES)
            throw(Exception("The specified heading style is not valid. "))
        else
            global actual_options = options
        end
    else
        global actual_options = MarkdownifyOptions(nothing, nothing, true, "underlined", "*+-")
    end
end
"""
    convert(html::AbstractString)
It converts the html string into a xml object.
"""
function convert(html::AbstractString)
    copy!(bs4, pyimport_conda("bs4", "beautifulsoup4", "rsmulktis"))

    html = wrap(html)
    soup = bs4.BeautifulSoup(html, "html.parser")
    process_tag(soup.find(id=FRAGMENT_ID), true)
end
"""
    manage_heading(attr::AbstractString)
It checks if the input is an heading attribute and return the function to call in order to manage it.
"""
function manage_heading(attr::AbstractString)
    # Handle headings
    #m = occursin(heading_re,attr)
    copy!(re, pyimport_conda("re", "re", "conda-forge"))

    m = match(r"^h(?<n>\d)", attr)
    if m != nothing
        n = m[:n]
        return "convert_hn"
    end
end
"""
    should_convert_tag(tag::AbstractString)
It verifies if the tag has to be managed or not based on the parameters.
"""
function should_convert_tag(tag::AbstractString)
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
"""
    indent(text::AbstractString, level::Int)
If text is not empty, it returns as many tabulations as the level parameters folowed by the text provided as input.
"""
function indent(text::AbstractString, level::Int)
    if isempty(text)
        return ""
    else
        return replace(text, r"^"ism => "\t"^level)
    end
end
"""
    underline(text::AbstractString, pad_char::AbstractString)
If text is not empty, it returns the text underlined by the pad_char.
"""
function underline(text::AbstractString, pad_char::AbstractString)
    text = rstrip(text)
    if isempty(text)
        return ""
    end

    return text*"\n"*(pad_char^length(text))*"\n\n"
end
"""
    convert_a(el, text::AbstractString)
It converts the tag <a> into either <href> or [text](href title) based on the parameters.
"""
function convert_a(el, text::AbstractString)
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
        title_part = " "*title
    end

    return "["*text*"]("*href*title_part*")"
end
"""
    convert_b(el, text::AbstractString)
It converts text into **text**.
"""
function convert_b(el, text::AbstractString)
    return convert_strong(el, text)
end

"""

"""
function convert_blockquote(el, text::AbstractString)
    #'\n' + line_beginning_re.sub('> ', text) if text else ''
    if text == nothing
        text = ""
    end
    return "\n"*replace(text, r"^"ism => "> ")
end

"""
    convert_br(el, text::AbstractString)
It converts <br> into "\n"
"""
function convert_br(el, text::AbstractString)
    return "  \n"
end

"""
    convert_em(el, text::AbstractString)
It converts text into *text*.
"""
function convert_em(el, text::AbstractString)
    if text == nothing
        return ""
    else
        return "*"*text*"*"
    end
end

"""
    convert_hn(el, text::AbstractString)
It renders the heading based on the heading tag and the parameters.
"""
function convert_hn(el, text::AbstractString)
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

"""
    convert_i(el, text::AbstractString)
It converts text into *text*.
"""
function convert_i(el, text::AbstractString)
    return convert_em(el, text)
end

"""
    convert_list(el, text::AbstractString)
It converts the list tag into a Markdown list.
"""
function convert_list(el, text::AbstractString)
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
"""
    convert_li(el, text::AbstractString)
It converts the li according to the parent list type.
"""
function convert_li(el, text::AbstractString)
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
        bullet = bullets[(depth % length(bullets))+1]
    end
    return bullet*" "*text*"\n"
end
"""
    convert_p(el, text::AbstractString)
It converts the text into the p tag into text\n\n
"""
function convert_p(el, text::AbstractString)
    if text == nothing
        return ""
    else
        return text*"\n\n"
    end
end
"""
    convert_span(el, text::AbstractString)
It converts the text into the span tag into text.
"""
function convert_span(el, text::AbstractString)
    if text == nothing
        return ""
    else
        return text
    end
end
"""
    convert_strong(el, text::AbstractString)
It converts the text into the strong tag into **text**
"""
function convert_strong(el, text::AbstractString)
    if text == nothing
        return ""
    else
        return "**"*text*"**"
    end
end
"""
    convert_img(el, text::AbstractString)
It converts the img tag into ![alt](src title_part).
"""
function convert_img(el, text::AbstractString)
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
"""
    function process_tag(node, children_only::Bool)
It process the tag and convert all the induced subtree into markdown.
"""
function process_tag(node, children_only::Bool)
    copy!(re, pyimport_conda("re", "re", "conda-forge"))
    copy!(six, pyimport_conda("six", "six", "conda-forge"))

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
"""
    process_text(text::AbstractString)
It escape the text and remove useless spaces.
"""
function process_text(text::AbstractString)
    if text!= ""
        return escape(replace(text, r"[\r\n\s\t ]+" => " "))
    else
        return text
    end
end
"""
    markdownify(html::AbstractString, Options::Union{MarkdownifyOptions,Nothing})
It converts the string html into a markdown string based on the specified options.
"""
function markdownify(html::AbstractString, options::Union{MarkdownifyOptions,Nothing})
    checkOptions(options)
    return convert(html)
end
