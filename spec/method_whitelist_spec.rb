describe Curlybars::MethodWhitelist do
  let(:dummy_class) { Class.new { extend Curlybars::MethodWhitelist } }

  describe "#allowed_methods" do
    it "should return an empty array as default" do
      expect(dummy_class.new.allowed_methods).to eq([])
    end
  end

  describe ".allow_methods" do
    before do
      link_presenter = Class.new
      article_presenter = Class.new

      dummy_class.class_eval do
        allow_methods :cook, link: link_presenter, article: article_presenter
      end
    end

    it "should set the allowed methods" do
      expect(dummy_class.new.allowed_methods).to eq([:cook, :link, :article])
    end

    it "raises when collection is not of presenters" do
      expect do
        dummy_class.class_eval { allow_methods :cook, links: ["foobar"] }
      end.to raise_error(RuntimeError)
    end

    it "raises when collection cardinality is greater than one" do
      stub_const("OnePresenter", Class.new { extend Curlybars::MethodWhitelist })
      stub_const("OtherPresenter", Class.new { extend Curlybars::MethodWhitelist })

      expect do
        dummy_class.class_eval { allow_methods :cook, links: [OnePresenter, OtherPresenter] }
      end.to raise_error(RuntimeError)
    end
  end

  describe "inheritance and composition" do
    let(:base_presenter) do
      link_presenter = Class.new

      Class.new do
        extend Curlybars::MethodWhitelist
        allow_methods :cook, link: link_presenter
      end
    end

    let(:helpers) do
      Module.new do
        extend Curlybars::MethodWhitelist
        allow_methods :form
      end
    end

    let(:post_presenter) do
      Class.new(base_presenter) do
        extend Curlybars::MethodWhitelist
        allow_methods :wave
      end
    end

    before do
      post_presenter.include helpers
    end

    it "should allow methods from inheritance and composition" do
      expect(post_presenter.new.allowed_methods).to eq([:cook, :link, :form, :wave])
    end
  end

  describe ".methods_schema" do
    before do
      stub_const("ArticlePresenter", Class.new { extend Curlybars::MethodWhitelist })
      stub_const("LinkPresenter", Class.new { extend Curlybars::MethodWhitelist })

      dummy_class.class_eval do
        allow_methods :cook, links: [LinkPresenter], article: ArticlePresenter
      end
    end

    it "should setup a schema of methods" do
      expect(dummy_class.methods_schema).
        to eq(cook: nil, links: [LinkPresenter], article: ArticlePresenter)
    end
  end

  describe ".dependency_tree" do
    before do
      link_presenter = Class.new do
        extend Curlybars::MethodWhitelist
        allow_methods :url
      end

      article_presenter = Class.new do
        extend Curlybars::MethodWhitelist
        allow_methods :title, :body
      end

      stub_const("ArticlePresenter", article_presenter)
      stub_const("LinkPresenter", link_presenter)

      dummy_class.class_eval do
        allow_methods :cook, links: [LinkPresenter], article: ArticlePresenter
      end
    end

    it "should return a dependencies tree" do
      expect(dummy_class.dependency_tree).
        to eq(
          cook: nil,
          links: [{ url: nil }],
          article: { title: nil, body: nil }
        )
    end
  end
end