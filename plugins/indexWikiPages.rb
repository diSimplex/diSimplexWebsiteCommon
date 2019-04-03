require 'xapian'
require 'xapianBase'

require 'uri'

module Fandian; module Wiki

  class IndexPage < Jekyll::Page
    def initialize(site, dir, pageList)
      @site = site
      @base = site.source
      @dir  = dir
      @name = 'index.html'

      puts "Adding IndexPage: #{dir}"

      self.process(@name)
      self.read_yaml(File.join(site.source, '_layouts'), 'emptyYaml.html')
      self.data['layout']        = 'index'
      self.data['title']         = dir

      breadCrumbs   = Array.new
      breadCrumbUrl = ''

      dir.sub(/^\//,'').split(/\//).each do | aDir |
        breadCrumbUrl << '/'+aDir
        breadCrumbs.push [ aDir, breadCrumbUrl+'/index.html' ]
      end

      self.data['breadCrumbs'] = breadCrumbs
      self.data['pageIndex']   = pageList
    end
  end

  class BuildWikiIndices < Jekyll::Generator
    include XapianBase

    safe true

    def wikiAnchor(wiki)
      "<a href=\"/wiki#{wiki.url}\">#{wiki.data['title']}</a>"
    end

    def xapianIndexWikiPage(page)
      title  = page.data['title']
      return if title.nil? || title.empty?

      url    = page.url
      anchor = wikiAnchor(page)

      doc = Xapian::Document.new()
      doc.data = anchor

      @xapianIndexer.document = doc
      @xapianIndexer.index_text_without_positions(
        removeStopWords(title), 1, 'S')
      @xapianIndexer.index_text_without_positions(
        removeStopWords(page.content), 1, 'XC') unless
        page.content.empty?

      # Add/replace the document to the database
      if @xapianDocId.has_key?(url) then
        puts "reIndexing: #{url}"
        @xapianDB.replace_document(@xapianDocId[url], doc)
      else
        puts "  Indexing: #{url}"
        @xapianDocId[url] = @xapianDB.add_document(doc)
      end
    end

    def addPageListToRootIndex(siteIndex, site)
      site.pages.each do | page |
        next unless page.name == 'index.md'
        next unless page.dir  == '/'

        pageList = Array.new
        siteIndex.keys.sort.each do | aDir |
          anIndex = siteIndex[aDir]

          next if aDir == 'index.md'

          thisDir = '/'+aDir
          if anIndex.is_a?(Hash) then
            pageList.push [aDir, thisDir+'/index.html' ]
          else
            pageList.push [aDir.sub(/\.[^\.]*$/,''), thisDir ]
          end
        end
        page.data['pageIndex'] = pageList
      end
    end

    def addIndexPages(parentIndex, baseDir, site)
      return unless parentIndex.is_a?(Hash);

      pageList = Array.new
      parentIndex.each_pair do | aDir, anIndex |
        thisDir = baseDir+'/'+aDir
        addIndexPages(anIndex, thisDir, site)
        if anIndex.is_a?(Hash) then
          pageList.push [aDir, thisDir+'/index.html' ]
        else
          title = anIndex.data['title']
          aDir = aDir.sub(/\.[^\.]*$/,'').sub(/^[0-9\-\/]+/,'')
          pageList.push [title, baseDir+'/'+aDir+'.html' ]
        end
      end
      site.pages << IndexPage.new(site, baseDir, pageList) unless
        baseDir.empty?
    end

    def addWikiLinks(item, wikiPages)
      item.content.gsub!(/\[\[([^\]|]*)(\|([^\]]*))?\]\]/) do
        link = $1
        desc = $3 ? $3 : $1

        link = '/' + link.downcase.strip.gsub(/\s+/,'_') + '.html'
        wikiPages[link] = Hash.new
        wikiPages[link]['found'] = false
        desc = desc.strip.gsub(/\s+/,' ')
        wikiPages[link]['title'] = desc
        link = URI::encode('/wiki' + link)

        "<a href=\"#{link}\">#{desc}</a>"
      end
    end

    def buildWikiPage(item, wikiIndex)
      parentIndex   = wikiIndex
      breadCrumbs   = Array.new
      breadCrumbUrl = ''
      itemPath = item.dir.sub(/^\//,'').split(/\//).each do | aDir |
        parentIndex[aDir] = Hash.new unless parentIndex.has_key?(aDir)
        parentIndex = parentIndex[aDir]
        breadCrumbUrl << '/'+aDir
        breadCrumbs.push [ aDir, breadCrumbUrl+'/index.html' ]
      end
      parentIndex[item.name] = item
      item.data['breadCrumbs'] = breadCrumbs
    end

    def generate(site)

      wikiIndex = Hash.new
      wikiPages = Hash.new

      setupXapian(site)

      # process page content adding wiki links and accumulate a hash of 
      # the linked pages
      #
      site.pages.each do | page |
        next if page.dir =~ /^\/partials/
        next if page.url =~ /^\/feed.xml/
        addWikiLinks(page, wikiPages)        
      end

      # scan through the collection of existing pages matching up 
      # implicit wiki pages
      #
      site.pages.each do | page |
        next if page.dir =~ /^\/partials/
        next if page.url =~ /^\/feed.xml/
        wikiPages[page.url]['found'] = true if wikiPages.has_key?(page.url)
      end

      # now create any implicit wiki pages which do not already exist
      #
      wikiPages.each_pair do | pageUrl, pageData |
        next if pageData['found']
        pageUrl = pageUrl.sub(/^\//,'').sub(/\.html$/,'.md')
        next if File.exists?(pageUrl)

        puts "ADDING stub wiki page: [#{pageUrl}]"
        File.open(pageUrl, 'w') do | pageFile |
          pageFile.puts "---"
          pageFile.puts "layout: page"
          pageFile.puts "title: #{pageData['title']}"
          pageFile.puts "---"
          pageFile.puts
        end
        site.pages << Jekyll::Page.new(site, site.source,
                                       File.dirname(pageUrl),
                                       File.basename(pageUrl))
      end

      site.pages.each do | page |
        next if page.dir =~ /^\/partials/
        next if page.url =~ /^\/feed.xml/
        buildWikiPage(page, wikiIndex)
        xapianIndexWikiPage(page)
      end

      addIndexPages(wikiIndex, '', site)
      addPageListToRootIndex(wikiIndex, site)

      closeDownXapian

    end
  end

end; end
