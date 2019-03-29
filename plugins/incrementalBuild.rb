# Provide our own crude regeneration dependency checks until we move to
# Jekyll 3.0
#
require 'rake/file_list'

module Jekyll

  module Convertible
    alias_method :orig_write, :write
    def write(dest)
      if !output.nil? && !output.empty? then
        puts destination(dest)+' ('+url+')'
        orig_write(dest)
      end
    end
  end

#  class Post
#      @@includesLayouts = nil
#
#    alias_method :orig_post_render, :render
#    def render(layouts, site_payload)
#      @@includesLayouts = Rake::FileList.new('_includes/*', '_layouts/*') if
#        @@includesLayouts.nil?
#      if path =~ /^partials\// || 
#         !File.exists?(path) || 
#         self.data.has_key?('renderNeeded') ||
#         !FileUtils.uptodate?(destination(site.dest), 
#                              [path, @@includesLayouts].flatten) then
#        puts path
#        orig_post_render(layouts, site_payload)
#      end
#    end
#  end

  class Page
    @@includesLayouts = nil

    attr_writer :converters, :url

    alias_method :orig_page_render, :render
    def render(layouts, site_payload)
      @@includesLayouts = Rake::FileList.new('_includes/*', '_layouts/*') if
        @@includesLayouts.nil?
      if path =~ /^partials\// ||
         !File.exists?(path) ||
         self.data.has_key?('renderNeeded') ||
         !FileUtils.uptodate?(destination(site.dest),
                              [path, @@includesLayouts].flatten) then
        puts path+' ('+output_ext+')'
        orig_page_render(layouts, site_payload)
      end
    end

  end

end


