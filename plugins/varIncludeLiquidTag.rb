require 'pp'

module Jekyll
  class VarIncludeLiquidTag < Liquid::Tag

    def initialize(tag_name, markup, options)

      @tag_name   = tag_name
      markupArray = markup.split
      @template_name = markupArray.shift.strip
      @variable_name = markupArray.shift.strip
    end

    def render(context)
#      puts "VarInclude render [#{context[@template_name]}] using [#{@variable_name}]"
      partial = load_cached_partial(context)
      context.stack do
        context[File.basename(context[@template_name],'.*')] = context[@variable_name]
        partial.render(context).strip
      end
    end

    def load_cached_partial(context)
      cached_partials = context.registers[:cached_partials] || {}
      template_name = context[@template_name]

      if cached = cached_partials[template_name]
        return cached
      end
      source = read_template_from_file_system(context)
      partial = Liquid::Template.parse(source)
      cached_partials[template_name] = partial
      context.registers[:cached_partials] = cached_partials
      partial
    end

    def read_template_from_file_system(context)
#      puts "VarInclude read_template [#{context[@template_name]}]"
      full_path = File.join('_includes', context[@template_name])
      raise Liquid::FileSystemError, 
        "No such template '#{context[@template_name]}'" unless
        File.exists?(full_path)
      File.read(full_path)
    end
  end
end

Liquid::Template.register_tag('varInclude', Jekyll::VarIncludeLiquidTag)

