#

require 'nokogiri'

module Jekyll
  module AnchorTargets

   def anchor_targets(html)
     html.gsub!(/href=\"http/,'target="_blank" href="http')
     html
   end

  end
end

Liquid::Template.register_filter(Jekyll::AnchorTargets)
