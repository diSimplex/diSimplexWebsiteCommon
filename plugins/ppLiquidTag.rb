
require 'pp'

module Jekyll
  class PpLiquidTag < Liquid::Tag

    def initialize(tag_name, variable, options)
      super
      @tag_name = tag_name
      @variable = variable.strip
    end

    def render(context)
      content = ""
      site = context.registers[:site]
      page = context.registers[:page]
      case @tag_name
      when 'site'
        content = site.pretty_inspect
      when 'siteConfig'
        content = config.pretty_inspect
      when 'siteData'
        if site.data.has_key?(@variable) then
          content = site.data[@variable].pretty_inspect
        else
          content = "the key [#{@variable}] has not been found in the site.data hash\n" + 
            site.data.pretty_inspect
        end
      when 'page'
        content = page.pretty_inspect
      when 'pp'
        if context.registers.has_key?(@variable) then
          content = context.registers[@variable].pretty_inspect
        else
          content = "the key [#{@variable}] has not been found in the context.registers hash\n" +
            context.registers.pretty_inspect
        end
      else
        content = "the key [#{@tag_name}] has not been found in the context.registers\n" +
          context.registers.pretty_inspect
      end
      content = '<pre>'+content+'</pre>'
      content
    end
  end
end

Liquid::Template.register_tag('pp', Jekyll::PpLiquidTag)
Liquid::Template.register_tag('site', Jekyll::PpLiquidTag)
Liquid::Template.register_tag('siteConfig', Jekyll::PpLiquidTag)
Liquid::Template.register_tag('siteData', Jekyll::PpLiquidTag)
Liquid::Template.register_tag('page', Jekyll::PpLiquidTag)



