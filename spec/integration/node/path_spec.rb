describe "path expansion on presenters" do
  let(:post) { double("post") }
  let(:presenter) { IntegrationTest::Presenter.new(double("view_context"), post: post) }

  it "evaluates the methods chain call" do
    doc = "{{user.avatar.url}}"
    lex = Curlybars::Lexer.lex(doc)

    ruby_code = Curlybars::Parser.parse(lex).compile
    rendered = eval(ruby_code)

    expect(rendered).to eq("http://example.com/foo.png")
  end

  it "raises when trying to call methods not implemented on context" do
      doc = "{{system}}"
      lex = Curlybars::Lexer.lex(doc)
      ruby_code = Curlybars::Parser.parse(lex).compile

      expect{eval(ruby_code)}.to raise_error(RuntimeError)
    end
end
