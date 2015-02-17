describe "block helper" do
  let(:post) { double("post") }
  let(:presenter) { IntegrationTest::Presenter.new(double("view_context"), post: post) }

  it "renders a helper with expression and options" do
    template = compile(<<-HBS.strip_heredoc)
      {{date user.created_at class='metadata'}}
    HBS

    expect(eval(template)).to resemble(<<-HTML.strip_heredoc)
      <time datetime="2015-02-03T13:25:06Z" class="metadata">
        February 3, 2015 13:25
      </time>
    HTML
  end

  it "renders a helper with only expression" do
    template = compile(<<-HBS.strip_heredoc)
      <script src="{{asset "jquery_plugin.js"}}"></script>
    HBS

    expect(eval(template)).to resemble(<<-HTML.strip_heredoc)
      <script src="http://cdn.example.com/jquery_plugin.js"></script>
    HTML
  end

  it "renders a helper with only options" do
    template = compile(<<-HBS.strip_heredoc)
      {{#with new_comment_form}}
        {{input title class="form-control"}}
      {{/with}}
    HBS

    expect(eval(template)).to resemble(<<-HTML.strip_heredoc)
      <input name="community_post[title]"
        id="community_post_title"
        type="text"
        class="form-control"
        value="some value persisted in the DB">
    HTML
  end
end
