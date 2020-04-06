# The local Jekyll based Xapian indexing commands for refs

require 'xapian'
require 'xapianBase'

module XapianIndexer

  include XapianBase

  def xapianIndexAuthorPage(page)
    pageData  = page[:metaData]
    return unless pageData.has_key?('biblatex')
    cleanName = pageData['biblatex']['cleanname']
    url       = page[:url]
    anchor    = "<a href=\"/refs/#{url}\">#{cleanName}</a>"

    doc = Xapian::Document.new()
    doc.data = anchor

    @xapianIndexer.document = doc
    @xapianIndexer.index_text_without_positions(
      removeStopWords(cleanName), 1, 'A')
    @xapianIndexer.index_text_without_positions(
      removeStopWords(pageData['biblatex']['entrytype']), 1, 'XT') if
      pageData['biblatex'].has_key?('entrytype')
    @xapianIndexer.index_text_without_positions(
      removeStopWords(page[:content]), 1, 'XC') unless
      page[:content].empty?
    @xapianIndexer.index_text_without_positions(
      removeStopWords(pageData['biblatex']['institution']), 1, 'XI') if
      pageData['biblatex'].has_key?('institution')

    # Add/replace the document to the database
    if @xapianDocId.has_key?(url) then
      puts "reIndexing: #{url}" unless @options.has_key?('quite')
      @xapianDB.replace_document(@xapianDocId[url], doc)
    else
      puts "  Indexing: #{url}" unless @options.has_key?('quite')
      @xapianDocId[url] = @xapianDB.add_document(doc)
    end
  end

  def xapianIndexCitationPage(page)
    pageData = page[:metaData]
    return unless pageData.has_key?('biblatex')
    biblatex = pageData['biblatex']
    title = biblatex['citekey']
    title = biblatex['title'] if biblatex.has_key?('title')
    url   = page[:url]
    authorsEditors = Array.new
    authorsEditors.concat(biblatex['author']) if biblatex.has_key?('author')
    authorsEditors.concat(biblatex['editor']) if biblatex.has_key?('editor')
    anchor = "<a href=\"/refs/#{url}\">#{title} (#{authorsEditors.join('; ')})</a>"

    doc = Xapian::Document.new()
    doc.data = anchor

    @xapianIndexer.document = doc
    biblatex.each_pair do | key, value |
      case key
      when @indexWithStopWords.has_key?(key)
        @xapianIndexer.index_text_without_positions(
          removeStopWords(value), 1, @indexWithStopWords[key])
      when 'date'
        @xapianIndexer.index_text_without_positions(
          value.to_s, 1, 'Y')
      end
    end
    @xapianIndexer.index_text_without_positions(
      removeStopWords(page[:content]), 1, 'XC') unless
      page[:content].empty?

    # Add/replace the document to the database
    if @xapianDocId.has_key?(url) then
      puts "reIndexing: #{url}" unless @options.has_key?('quite')
      @xapianDB.replace_document(@xapianDocId[url], doc)
    else
      puts "  Indexing: #{url}" unless @options.has_key?('quite')
      @xapianDocId[url] = @xapianDB.add_document(doc)
    end
  end

  def xapianIndexPage(page)
    case page[:file]
    when /^\.\/author/
      xapianIndexAuthorPage(page)  
    when /^\.\/cite/
      xapianIndexCitationPage(page)
    end
  end

  def setupIndexer
    @indexWithStopWords = YAML::load_file('_data/biblatexFieldsXapianTerms.yml')
  end

end # XapianLocal
