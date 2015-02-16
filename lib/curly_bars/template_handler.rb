require 'active_support'
require 'action_view'
require 'curlybars'
require 'curly/template_handler'
require 'curly/presenter_not_found'
require 'curly_bars/lexer'
require 'curly_bars/parser'

class CurlyBars::TemplateHandler < Curly::TemplateHandler
  class << self

    private

    def compile(template)
      # Template is empty, so there's no need to initialize a presenter.
      return %("") if template.source.empty?

      path = template.virtual_path
      presenter_class = Curly::Presenter.presenter_for_path(path)

      raise Curly::PresenterNotFound.new(path) if presenter_class.nil?

      lex = CurlyBars::Lexer.lex(template.source)
      source = CurlyBars::Parser.parse(lex).compile

      code = <<-RUBY
      if local_assigns.empty?
        options = assigns
      else
        options = local_assigns
      end

      presenter = ::#{presenter_class}.new(self, options)
      presenter.setup!

      @output_buffer = output_buffer || ActiveSupport::SafeBuffer.new

      Curly::TemplateHandler.cache_if_key_is_not_nil(self, presenter) do
        safe_concat begin
          #{source}
        end
      end

      @output_buffer

      RUBY

      code
    end

    def instrument(template, &block)
      payload = { path: template.virtual_path }
      ActiveSupport::Notifications.instrument("compile.curlybars", payload, &block)
    end
  end
end