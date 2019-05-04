using PyCall
using Test, Markdownify
#setup code

@testset "Test Basic" begin
    @test markdownify("<span>Hello</span>",nothing) == "Hello"
    @test markdownify(" a  b \n\n c ", nothing) == " a b c "
end;

@testset "Test Conversions" begin
    @test markdownify("",nothing) == ""

    @test markdownify("<i>Hello</i>",nothing) == "*Hello*"
    @test markdownify("<em>Hello</em>",nothing) == "*Hello*"

    @test markdownify("<b>Hello</b>",nothing) == "**Hello**"
    @test markdownify("<strong>Hello</strong>",nothing) == "**Hello**"

    @test markdownify("<p>Hello</p>",nothing) == "Hello\n\n"

    @test markdownify("<a href='http://google.com'>Google</a>",nothing) == "[Google](http://google.com)"
    @test markdownify("<a href='http://google.com'>http://google.com</a>",nothing) == "<http://google.com>"
    @test markdownify("<a href='http://google.com'>http://google.com</a>",MarkdownifyOptions(nothing, nothing, false, "underlined", "*+-")) == "[http://google.com](http://google.com)"
    @test markdownify("<a href='http://google.com'title='Google'>http://google.com</a>",MarkdownifyOptions(nothing, nothing, false, "underlined", "*+-")) == "[http://google.com](http://google.com Google)"

    @test strip(markdownify("<blockquote>Hello</blockquote>", nothing)) == "> Hello"

    @test markdownify("a<br />b<br />c", nothing) == "a  \nb  \nc"

    @test markdownify("<h1></h1>", nothing) == ""
    @test markdownify("<h1>Hello</h1>", nothing) == "Hello\n=====\n\n"
    @test markdownify("<h1>Hello</h1>", MarkdownifyOptions(nothing, nothing, false, "atx_closed", "*+-")) == "# Hello #\n\n"
    @test markdownify("<h2>Hello</h2>", nothing) == "Hello\n-----\n\n"
    @test markdownify("<h2>Hello</h2>", MarkdownifyOptions(nothing, nothing, false, "atx_closed", "*+-")) == "## Hello ##\n\n"
    @test markdownify("<h3>Hello</h3>", nothing) == "### Hello\n\n"
    @test markdownify("<h6>Hello</h6>", nothing) == "###### Hello\n\n"

    @test markdownify("<ol><li>a</li><li>b</li></ol>", nothing) == "1. a\n2. b\n"
    @test markdownify("<ul><li>a</li><li>b</li></ul>", nothing) == "* a\n* b\n"

    @test markdownify("<img src='/path/to/img.jpg' alt='Alt text' title='Optional title' />", nothing) == "![Alt text](/path/to/img.jpg 'Optional title')"
    @test markdownify("<img src='/path/to/img.jpg' alt='Alt text' />", nothing) == "![Alt text](/path/to/img.jpg)"

end;

@testset "Test Escaping" begin
    @test markdownify("_hey_dude_", nothing) == "\\_hey\\_dude\\_"
    @test markdownify("&amp;",nothing) == "&"
    @test markdownify("&amp;amp;",nothing) == "&amp;"

end;


@testset "Test Args" begin
    @test markdownify("<a href='https://github.com/matthewwithanm'>Some Text</a>", MarkdownifyOptions(["a"], nothing, false, "underlined", "*+-"))== "Some Text"
    @test markdownify("<a href='https://github.com/matthewwithanm'>Some Text</a>", MarkdownifyOptions([], nothing, false, "underlined", "*+-")) == "[Some Text](https://github.com/matthewwithanm)"
    @test markdownify("<a href='https://github.com/matthewwithanm'>Some Text</a>", MarkdownifyOptions(nothing, ["a"], false, "underlined", "*+-"))== "[Some Text](https://github.com/matthewwithanm)"
    @test markdownify("<a href='https://github.com/matthewwithanm'>Some Text</a>", MarkdownifyOptions(nothing, [], false, "underlined", "*+-"))== "Some Text"
    @test_throws Exception markdownify("<a href='https://github.com/matthewwithanm'>Some Text</a>", MarkdownifyOptions([], [], false, "underlined", "*+-"))
    @test_throws Exception markdownify("<a href='https://github.com/matthewwithanm'>Some Text</a>", MarkdownifyOptions(nothing, [], false, "not exist", "*+-"))
end;

@testset "Test Nested" begin
    @test markdownify("<p>This is an <a href='http://example.com/'>example link</a>.</p>",nothing) == "This is an [example link](http://example.com/).\n\n"

    nested_uls = "
        <ul>
            <li>1
                <ul>
                    <li>a
                        <ul>
                            <li>I</li>
                            <li>II</li>
                            <li>III</li>
                        </ul>
                    </li>
                    <li>b</li>
                    <li>c</li>
                </ul>
            </li>
            <li>2</li>
            <li>3</li>
        </ul>"
    nested_uls = replace(nested_uls, r"\s+"=>"")

    @test markdownify(nested_uls, nothing) == "* 1\n\t+ a\n\t\t- I\n\t\t- II\n\t\t- III\n\t\n\t+ b\n\t+ c\n\n* 2\n* 3\n"
    @test markdownify(nested_uls, MarkdownifyOptions(nothing, nothing, true, "underlined", "-")) == "- 1\n\t- a\n\t\t- I\n\t\t- II\n\t\t- III\n\t\n\t- b\n\t- c\n\n- 2\n- 3\n"

    @test strip(markdownify("<blockquote>And she was like <blockquote>Hello</blockquote></blockquote>",nothing)) == "> And she was like \n> > Hello"
end;
