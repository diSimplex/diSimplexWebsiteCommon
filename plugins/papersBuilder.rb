#require 'jekyll/utils'

# This ruby based Jekyll plugin provides a reference based page builder

require 'baseCommands'
require 'cachedBuilder'
require 'indexBuilder'
require 'papersLiquidTags'
require 'websiteMappingLiquidTag'
require 'varIncludeLiquidTag'

module ReferenceBuilder

  def page2liquid(page)
    fileName = File.basename(page[:file], '.md')
    deep_merge_hashes(
      page[:metaData],
      {
        "content"       => page[:content],
        "path"          => page[:file],
        "url"           => page[:url],
        "biblatexUrl"   => page[:url].sub(/\.html/, '.bib'),
        "bibcontextUrl" => page[:url].sub(/\.html/, '.lua'),
        "paperPdf"      => page[:url].sub(/\.html/, "/#{fileName}.pdf"),
        "paperPdf2Html" => page[:url].sub(/\.html/, "/#{fileName}.html"),
        "papersUrl"     => page[:url].sub(/\.html/, 'Papers.html')
      }
    )
  end

  def checkAuthorPage(anAuthor)
    authorFile = author2urlBase(anAuthor)+'.md'
    if not File.exist?(authorFile) then
      authorNames = anAuthor.split(/,/)
      surname   = authorNames.shift
      firstName = authorNames.join(',')
      FileUtils.mkdir_p(File.dirname(authorFile))
      File.open(authorFile, 'w') do | aFile |
        aFile.puts('---')
        aFile.puts('layout: author')
        aFile.puts("title: \"#{anAuthor}\"")
        aFile.puts("firstName: \"#{firstName}\"")
        aFile.puts("surName: \"#{surname}\"")
        aFile.puts('---')
        aFile.puts('')
        aFile.puts("# #{anAuthor}")
      end
    end
  end

  def checkKeywordPage(aKeyword)
    keywordFile = keyword2urlBase(aKeyword)+'.md'
    if not File.exist?(keywordFile) then
      FileUtils.mkdir_p(File.dirname(keywordFile))
      File.open(keywordFile, 'w') do | kFile |
        kFile.puts('---')
        kFile.puts('layout: keyword')
        kFile.puts("title: \"#{aKeyword}\"")
        kFile.puts('---')
        kFile.puts('')
        kFile.puts("# #{aKeyword}")
      end
    end
  end

  def checkPaperPage(aPaper, aTitle, anAbstract)
    paperFile = paper2urlBase(aPaper)+'.md'
    if not File.exist?(paperFile) then
      FileUtils.mkdir_p(File.dirname(paperFile))
      File.open(paperFile, 'w') do | kFile |
        kFile.puts('---')
        kFile.puts('layout: paper')
        kFile.puts("title: \"#{aTitle}\"")
        kFile.puts('---')
        kFile.puts('')
        kFile.puts(anAbstract)
      end
    end
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

  def addPaperItem(index, year, citeKey, url, title)
    indexKey = "#{year}#{citeKey}"
    linkText = "#{year} #{citeKey}"
    index[indexKey] = {
      'url'      => url,
      'linkText' => linkText.gsub(/\s/,' '),
      'auxText'  => title
    }
  end

  def addPaperAbstractPages(page)
    puts "addPaperAbstractPages"
    metaData = page[:metaData]
    aPaper = File.basename(page[:file], '.md')
    checkPaperPage(aPaper, metaData['title'], page[:content])
    paperPath = paper2urlBase(aPaper)+'Papers.md'
    paperUrl  = paperPath.sub(/\.md$/, '.html')
    papers    = loadJekyllDataFile(paperPath)
    papers[:changed]              = true
    papers[:metaData]['layout']   = "paperVersions"
    papers[:metaData]['citeKeys'] = Hash.new unless
      papers[:metaData].has_key?('citeKeys')
    addPaperItem(papers[:metaData]['citeKeys'],
                    metaData['year'], metaData['citekey'],
                    page[:url], metaData['title'])
  end

  def addAuthorAbstractPages(page)
    metaData = page[:metaData]
    metaData['authors'].each do | anAuthor |
      checkAuthorPage(anAuthor)
      paperPath = author2urlBase(anAuthor)+'Papers.md'
      paperUrl  = paperPath.sub(/\.md$/, '.html')
      papers    = loadJekyllDataFile(paperPath)
      papers[:changed]              = true
      papers[:metaData]['layout']   = "authorPapers"
      papers[:metaData]['citeKeys'] = Hash.new unless
        papers[:metaData].has_key?('citeKeys')
      addPaperItem(papers[:metaData]['citeKeys'],
                      metaData['year'], metaData['citekey'],
                      page[:url], metaData['title'])
    end
  end

  def addKeywordAbstractPages(page)
    metaData = page[:metaData]
    metaData['keywords'].each do | aKeyword |
      checkKeywordPage(aKeyword)
      paperPath = keyword2urlBase(aKeyword)+'Papers.md'
      paperUrl  = paperPath.sub(/\.md$/, '.html')
      papers    = loadJekyllDataFile(paperPath)
      papers[:changed]              = true
      papers[:metaData]['layout']   = "keywordPapers"
      papers[:metaData]['citeKeys'] = Hash.new unless
        papers[:metaData].has_key?('citeKeys')
      addPaperItem(papers[:metaData]['citeKeys'],
                      metaData['year'], metaData['citekey'],
                      page[:url], metaData['title'])
    end
  end

  def sanitizeAbstractMetaData(page)
    metaData = page[:metaData]

    if metaData.has_key?('author') then
      metaData['authors'] = metaData['author']
      metaData.delete('author')
    end
    metaData['authors'] =
      [ 'Unknown, Unknown' ] unless metaData.has_key?('authors')

    metaData['keywords'] = [ ] unless metaData.has_key?('keywords')

    metaData['year'] =
      Date.today.year.to_s unless metaData.has_key?('year')

    authorPrefix = metaData['authors'].map do | anItem |
      anItem.split(/,/).shift
    end.join('')
    citekey =
      authorPrefix + metaData['year'].to_s + File.basename(page[:file], '.md')
    citekey[0] = citekey[0].downcase
    metaData['citekey'] = citekey

    page[:metaData] = metaData
  end

  def buildWorkingDraft(page, site)
    sanitizeAbstractMetaData(page)
    addDirIndexPages("workingDraft", "WorkingDraft", page)
    addPaperAbstractPages(page)
    addAuthorAbstractPages(page)
    addKeywordAbstractPages(page)
    renderPage(page, site)
    #renderPage(createBibLaTeXPage(page), site)
    #renderPage(createBibConTeXtPage(page), site)
    dirPath = page[:file].gsub(/\.md$/,'')
    sitePath = '_site/'+dirPath
    puts "Removing [#{sitePath}]"
    FileUtils.rm_rf(sitePath)
    puts "Copying [#{dirPath}] to [#{sitePath}]"
    FileUtils.cp_r(dirPath, sitePath)
    removeFromDataFileCache(page[:file])
  end

  def buildPaper(page, site)
    renderPage(page, site)
    addIndexPages("paper", "Paper", page)
    removeFromDataFileCache(page[:file])
  end

  def buildAuthor(page, site)
    renderPage(page, site)
    addIndexPages("author", "Author", page)
    removeFromDataFileCache(page[:file])
  end

  def buildKeyword(page, site)
    renderPage(page, site)
    addIndexPages("keyword", "Keyword", page)
    removeFromDataFileCache(page[:file])
  end

  def buildList
    [ "referenceSchemas", "workingDraft", "paper", "author", "keyword" ]
  end

  def buildPage(page, site)
    case page[:file]
    when /^workingDraft/
      buildWorkingDraft(page, site)
    when /^paper/
      buildPaper(page, site)
    when /^author/
      buildAuthor(page, site)
    when /^keyword/
      buildKeyword(page, site)
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
    extend Jekyll::Keyword2UrlFilter
    extend Jekyll::Paper2UrlFilter

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
        c.description 'papers build command'
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

          # rsync the (human) _overlay on top of the papers directory
          system("rsync -arv _overlay/ .")

          # do this by hand...
          buildPage(loadJekyllDataFile("index.md"), site) unless
            FileUtils.uptodate?(LAST_BUILD, [ "index.md" ])

          recursivelyWalkDir(buildList(), LAST_BUILD) do | someJekyllData |
            # we explicitly ignore index and citation files...
            # they will be processed if needed during the renderDataFileCache
            #
            next if someJekyllData[:file] =~ /.+index\.md$/
            next if someJekyllData[:file] =~ /Papers\.md$/

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
