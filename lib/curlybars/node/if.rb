module Curlybars
  module Node
    If = Struct.new(:expression, :template) do
      def compile
        <<-RUBY
          buffer = ActiveSupport::SafeBuffer.new
          if hbs.to_bool(#{expression.compile}.call)
            buffer.safe_concat(#{template.compile})
          end
          buffer
        RUBY
      end
    end
  end
end
