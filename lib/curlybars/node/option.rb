module Curlybars
  module Node
    Option = Struct.new(:key, :expression) do
      def compile
        <<-RUBY
          { #{key.to_s.inspect} => #{expression.compile}.call }
        RUBY
      end
    end
  end
end