#require 'jekyll/utils'

# This ruby based Jekyll plugin provides a reference based page builder

require 'baseCommands'
require 'cachedBuilder'
require 'indexBuilder'
require 'refsLiquidTags'
require 'websiteMappingLiquidTag'
require 'varIncludeLiquidTag'

module ReferenceBuilder

  def page2liquid(page)
    deep_merge_hashes(
      page[:metaData],
      {
        "content"       => page[:content],
        "path"          => page[:file],
        "url"           => page[:url],
        "biblatexUrl"   => page[:url].sub(/\.html/, '.bib'),
        "bibcontextUrl" => page[:url].sub(/\.html/, '.lua'),
        "citationsUrl"  => page[:url].sub(/\.html/, 'Citations.html')
      }
    )
  end

 def createBibLaTeXPage(page)
    biblatexPage = page.clone
    biblatexPage[:metaData]['layout'] = 'biblatex'
    biblatexPage[:url] = page[:url].sub(/\.html$/,'.bib')
    biblatexPage
  end

  def createBibConTeXtPage(page)
    bibcontextPage = page.clone
    bibcontextPage[:metaData]['layout'] = 'bibcontext'
    bibcontextPage[:url] = page[:url].sub(/\.html$/,'.lua')
    bibcontextPage
  end

  def addCitationItem(index, year, citeKey, url, title)
    indexKey = "#{year}#{citeKey}"
    linkText = "#{year} #{citeKey}"
    index[indexKey] = {
      'url'      => url,
      'linkText' => linkText.gsub(/\s/,' '),
      'auxText'  => title
    }
  end

  def addAuthorCitationPages(page)
    biblatex = page[:metaData]['biblatex']
    ['author', 'bookauthor', 'commentator',
     'editor', 'editora', 'editorb', 'editorc',
     'holder', 'translator'].each do | aNameField |
      if biblatex.include?(aNameField) then
        biblatex[aNameField].each do | anAuthor |
          citationPath = author2urlBase(anAuthor)+'Citations.md'
          citationUrl  = citationPath.sub(/\.md$/, '.html')
          citations    = loadJekyllDataFile(citationPath)
          citations[:changed]              = true
          citations[:metaData]['layout']   = "authorCitations"
          citations[:metaData]['citeKeys'] = Hash.new unless
            citations[:metaData].has_key?('citeKeys')
          addCitationItem(citations[:metaData]['citeKeys'],
                          biblatex['year'], biblatex['citekey'],
                          page[:url], biblatex['title'])
        end
      end
    end
  end

  def buildCitation(page, site)
    addIndexPages("cite", "Citation", page)
    addAuthorCitationPages(page)
    renderPage(page, site)
    renderPage(createBibLaTeXPage(page), site)
    renderPage(createBibConTeXtPage(page), site)
    removeFromDataFileCache(page[:file])
  end

  def buildAuthor(page, site)
    renderPage(page, site)
    addIndexPages("author", "Author", page)
    removeFromDataFileCache(page[:file])
  end

  def buildList
    [ "referenceSchemas", "cite", "author" ]
  end

  def buildPage(page, site)
    case page[:file]
    when /^cite/
      buildCitation(page, site)
    when /^author/
      buildAuthor(page, site)
    else
      buildAPage(page, site)
    end
  end

end # ReferenceBuilder

module Octopress

#=begin
  class BuildCommand < Command
    extend Jekyll::Utils

    require 'jekyllWalker'
    extend JekyllWalker
    extend CachedBuilder
    extend IndexBuilder
    extend ReferenceBuilder

    extend Jekyll::Author2UrlFilter

    class << self
      # monkey patch ourself so that we can implement selective caching
      alias_method :origLoadJekyllDataFile, :loadJekyllDataFile
      alias_method :loadJekyllDataFile,      :cachingLoadJekyllDataFile
    end

    LAST_BUILD = "_site/.lastBuild"

    def self.init_with_program(p)
      p.commands.delete(:build) if p.commands.has_key?(:build)
      p.commands.delete(:b)     if p.commands.has_key?(:b)
      p.command(:build) do |c|
        c.syntax 'build'
        c.description 'my build command'
        c.option 'quite',   '-q', '--quite',   'keep quite about loading/writing'
        c.option 'verbose', '-v', '--verbose', 'report when we load/write files'
        c.action do | args, options |
          options['quite'] = true unless options['verbose']
          options.delete('save')
          @options = options
          clearDataFileCache
          siteOpts = Jekyll.configuration(options)
          site = Jekyll::Site.new(siteOpts)
          site.layouts = Jekyll::LayoutReader.new(site).read
          site.data = Jekyll::DataReader.new(site).read(site.config["data_dir"])
          FileUtils.mkdir_p(site.config['destination'])

          # do this by hand...
          buildPage(loadJekyllDataFile("index.md"), site) unless
            FileUtils.uptodate?(LAST_BUILD, [ "index.md" ])

          recursivelyWalkDir(buildList(), LAST_BUILD) do | someJekyllData |
            # we explicitly ignore index and citation files...
            # they will be processed if needed during the renderDataFileCache
            #
            next if someJekyllData[:file] =~ /.+index\.md$/
            next if someJekyllData[:file] =~ /Citations\.md$/

            buildPage(someJekyllData, site)

            # we DO NOT want the standard walker saving behaviour
            #
            someJekyllData.delete(:changed)
          end
          renderDataFileCache(site)
          FileUtils.touch(LAST_BUILD)
        end
      end
    end
  end
#=end

  class IndexCommand < Command
    require 'jekyllWalker'
    extend JekyllWalker

    require 'xapianBase'
    extend XapianBase

    XAPIAN_LAST_REINDEX = "xapian/lastReIndex"

    def self.init_with_program(p)
      p.commands.delete(:index) if p.commands.has_key?(:index)
      p.commands.delete(:i)     if p.commands.has_key?(:i)
      p.command(:index) do |c|
        c.syntax 'index'
        c.alias :idx
        c.description 're-Build the Xapian indexes'
        c.option 'quite',   '-q', '--quite',   'keep quite about loading/writing'
        c.option 'verbose', '-v', '--verbose', 'report when we load/write files'

        c.action do | args, options |
          options['quite'] = true unless options['verbose']
          @options = options
          extend XapianIndexer

          puts ""
          system('rm -rf xapian')
          puts "Recreating Xapian"
          siteOpts = Jekyll.configuration(options)
          site = Jekyll::Site.new(siteOpts)
          setupXapian(site)
          setupIndexer
          recursivelyWalkDir(".", XAPIAN_LAST_REINDEX) do | someJekyllData |
            someJekyllData[:url] =
              someJekyllData[:file].sub(/\.md$/,'.html').sub(/^\.\//,'')
            xapianIndexPage(someJekyllData)
          end
          closeDownXapian
          FileUtils.touch(XAPIAN_LAST_REINDEX)
          FileUtils.remove_dir('_site/xapian', true)
          FileUtils.mkdir_p('_site')
          FileUtils.cp_r('xapian', '_site')
        end
      end
    end
  end # IndexCommand

end # Octopress
