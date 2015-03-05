module Curlybars
  class RenderingSupport
    def initialize(contexts, file_name)
      @contexts = contexts
      @file_name = file_name
    end

    def check_context_is_presenter(context, path, position)
      return if context.respond_to?(:allows_method?)
      message = "`#{path}` is not a context type object"
      raise Curlybars::Error::Render.new('context_is_not_a_presenter', message, position)
    end

    def check_context_is_array_of_presenters(collection, path, position)
      return if collection.respond_to?(:each) && collection.all? do |presenter|
        presenter.respond_to? :allows_method?
      end

      message = "`#{path}` is not an array of presenters"
      raise Curlybars::Error::Render.new('context_is_not_an_array_of_presenters', message, position)
    end

    def to_bool(condition)
      condition != false &&
        condition != [] &&
        condition != 0 &&
        condition != '' &&
        !condition.nil?
    end

    def path(path, position)
      chain = path.split(/\./)
      method_to_return = chain.pop

      resolved = chain.inject(contexts.last) do |context, meth|
        raise_if_not_traversable(context, meth, position)
        context.public_send(meth)
      end

      raise_if_not_traversable(resolved, method_to_return, position)
      resolved.method(method_to_return.to_sym)
    end

    ALLOWED_KEYWORD_PARAMETERS = [:context, :options]

    def call(helper, helper_path, helper_position, context, options, &block)
      parameters = helper.parameters

      unallowed_parameters = parameters.reject do |type, name|
        type == :keyreq && ALLOWED_KEYWORD_PARAMETERS.include?(name)
      end

      if unallowed_parameters.any?
        file_path = helper.source_location.first
        line_number = helper.source_location.last

        message = "#{file_path}:#{line_number} - `#{helper_path}` bad signature "
        message << "for helper #{helper} - possible keyword parameters are context: and options:"
        raise Curlybars::Error::Render.new('invalid_helper_signature', message, helper_position)
      end

      parameters_name = parameters.map(&:last)
      arguments = {}
      arguments.merge!(context: context) if parameters_name.include? :context
      arguments.merge!(options: options) if parameters_name.include? :options

      if arguments.any?
        helper.call(**arguments, &block)
      else
        helper.call(&block)
      end
    end

    def position(line_number, line_offset)
      Curlybars::Position.new(file_name, line_number, line_offset)
    end

    private

    attr_reader :contexts, :file_name

    def raise_if_not_traversable(context, meth, position)
      check_context_is_presenter(context, meth, position)
      check_context_allows_method(context, meth, position)
      check_context_has_method(context, meth, position)
    end

    def check_context_allows_method(context, meth, position)
      return if context.allows_method?(meth.to_sym)
      message = "`#{meth}` is not available."
      message += "Add `allow_methods :#{meth}` to #{context.class} to allow this path"
      raise Curlybars::Error::Render.new('path_not_allowed', message, position)
    end

    def check_context_has_method(context, meth, position)
      return if context.respond_to?(meth.to_sym)
      message = "`#{meth}` is not available in #{context.class}"
      raise Curlybars::Error::Render.new('path_not_allowed', message, position)
    end
  end
end