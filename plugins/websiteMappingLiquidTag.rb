

module Jekyll
  class WebsiteMappingLiquidTag < Liquid::Tag

    def initialize(tag_name, webSiteUrl, options)
      super
      @tagName = tag_name
      @webSiteUrl = webSiteUrl.strip
    end

    def render(context)
      site = context.registers[:site]
      fullUrl = 'no website mapping found'
      parts = @webSiteUrl.split(/:/)
      if !parts.nil? then
        if 1 < parts.length then
          webSiteName = parts[0]
          relativeUrl = parts[1]
          if site.data.has_key?('websiteMapping') && 
            site.data['websiteMapping'].has_key?(webSiteName) then
            fullUrl = site.data['websiteMapping'][webSiteName]
            fullUrl +='/' unless relativeUrl[0] == '/'
            fullUrl +=relativeUrl
          end
        else
          fullUrl = parts[0]
        end
      end
      content = fullUrl
      content = "(#{fullUrl})" unless @tagName == 'webRaw'
      content
    end
  end
end

Liquid::Template.register_tag('web', Jekyll::WebsiteMappingLiquidTag)
Liquid::Template.register_tag('webRaw', Jekyll::WebsiteMappingLiquidTag)
