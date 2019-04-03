# This ruby base Jekyll plugin provides a simplistic cached builder
#

# This code has been adapted from jekyll versions 2.x and updated for 
# version 3.x. This code may be made redundant with Jeykyll 4.0

#require 'jekyll/utils'

module CachedBuilder

# Any complete Cached based Builder needs:
#  page2liquid(page)

  def renderContentLiquid(content, payload, info)
    Liquid::Template.parse(content).render!(payload, info)
  end

  def renderContentMarkdown(content)
    Kramdown::Document.new(content).to_html
  end

  def renderPageLiquid(output, page, site, payload, info)
    output = output.dup
    layout = site.layouts[payload['page']['layout']]

    used   = Set.new([layout])
    while layout
      payload = deep_merge_hashes(
        payload, 
        {
          "content" => output,
          "page"    => page2liquid(page),
          "layout"  => layout.data
        }
      )
      output = renderContentLiquid(
        layout.content,
        payload,
        info
      )
      layout = site.layouts[layout.data["layout"]]
      if layout then
        if used.include?(layout)
          layout = nil
        else
          used << layout
        end
      end
    end
    output
  end

  def renderPage(page, site)
    payload = deep_merge_hashes({
      "page" => deep_merge_hashes( 
        page[:metaData],
        page2liquid(page)
      )
    }, site.site_payload)

    info = {
      filters:   [Jekyll::Filters],
      registers: { :site => site, :page => payload['page'] }
    }

    output = page[:content]
    output = renderContentLiquid(output, payload, info)
    output = renderContentMarkdown(output)
    output = renderPageLiquid(output, page, site, payload, info)
    return if output.nil? or output.empty?

    outFileName = site.config['destination']+'/'+page[:url]
    FileUtils.mkdir_p(File.dirname(outFileName))
    File.open(outFileName, 'w') do | outfile |
      outfile.write(output)
    end
  end

  def clearDataFileCache
    @jekyllDataFiles = Hash.new
  end

  def cachingLoadJekyllDataFile(aJekyllDataFile)
    return @jekyllDataFiles[aJekyllDataFile] if
      @jekyllDataFiles.has_key?(aJekyllDataFile)
    #puts "loading: [#{aJekyllDataFile}]"
    someJekyllData = origLoadJekyllDataFile(aJekyllDataFile)
    @jekyllDataFiles[aJekyllDataFile] = someJekyllData

    someJekyllData
  end

  def removeFromDataFileCache(aJekyllDataFile)
    @jekyllDataFiles.delete(aJekyllDataFile)
  end

  def buildAPage(page, site)
    renderPage(page, site)
    removeFromDataFileCache(page[:file])
  end

end # CachedBuilder
