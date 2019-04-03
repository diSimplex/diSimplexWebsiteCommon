require 'refsLiquidTags'

module Octopress

  module RefCommandUtils

    # taken-from / similar-to refs/_bin/walkerUtils.rb
    def loadJekyllDataFile(aJekyllDataFile)
#      puts '  Loading: '+aJekyllDataFile
      jekyllData = { file: aJekyllDataFile }
      content = File.read(aJekyllDataFile)
#      puts content.encoding
      jekyllData[:content] = content
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        jekyllData[:metaData] = SafeYAML.load($1)
        jekyllData[:content].sub!(/\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m, '')
      end
#      reportEncoding(jekyllData)
      jekyllData
    end

    def checkForCitation(citeKey)
      possibleCitations = Dir.glob("cite/*/#{citeKey[0, 5]}*").sort;
      return 'new' if possibleCitations.empty?

      puts "\nDo you want to use one of these existing citations?"
      possibleCitations.size.times do | i |
        puts "#{(i+1)}: #{possibleCitations[i]}"
      end
      index = Readline.readline( "index (or return to add new citation): ", true)
      puts ""
      index = index.to_i
      return possibleCitations[index-1] if (0 < index) &&
        (index < possibleCitations.size+1)

      return 'new'
    end

    def selectDocType
      puts "\nSelect docType"
      docTypes = [ "owned", "public", "purchased", "uncatalogued", "unknown", "workingCopies"]
      docTypes.size.times do | i |
        puts "#{(i+1)}: #{docTypes[i]}"
      end
      index = Readline.readline("index (or return for unknown): ", true)
      index = index.to_i
      return docTypes[index-1] if (0 < index) && (index < docTypes.size+1)
      return "unknown"
    end

    def gatherNamesFor(aNameField)
      puts "\nGathering names for '#{aNameField}'"
      names = Array.new
      while true do 
        aName = addAuthor({})
        return names if aName.nil?
        names.push(aName)
      end
    end

    def addCitation(options, citationType, biblatexTypes)
      options['template'] = 'citation'
      options['type']     = 'citation'
      options['layout']   = 'citation'
      biblatex = Hash.new
      biblatex['entrytype'] = citationType
      citationData = biblatexTypes[citationType]
      biblatexFields = citationData['requiredFields'].sort
      biblatexFields.concat citationData['usefulFields'].sort
      biblatexFields.reject! { | field | field =~ /\[/ }
      options['biblatexFields'] = biblatexFields
      #
      # start by getting the citeKey and checking if it already 
      # exists
      #
      biblatex['citekey'] = 
        Readline.readline( 'citekey: ', true)
      citationPath = checkForCitation(biblatex['citekey'])
      if citationPath == 'new' then
        #
        # now select the docType
        #
        biblatex['docType'] = selectDocType
        #
        # now get the name fields into YAML arrays
        #
        ['author', 'bookauthor', 'commentator',
         'editor', 'editora', 'editorb', 'editorc',
         'holder', 'translator'].each do | aNameField |
          if biblatexFields.include?(aNameField) then
            names = gatherNamesFor(aNameField)
            if names.nil? || names.empty? then
              biblatex[aNameField] = "[]"
            else
              biblatex[aNameField] = "\n  - "+names.join("\n  - ")
            end
          end
        end
        #
        # now get all of the other fields
        #
        biblatexFields.each do | field |
          biblatex[field] =
            Readline.readline( field+': ', true) unless
            biblatex.has_key?(field)
        end
        #
        # fix year-date
        #
        if biblatex.has_key?('year-date') then
          biblatexFields.delete('year-date')
          if !biblatex['year-date'].nil? && !biblatex['year-date'].empty? then
            if biblatex['year-date'] =~ /[\-\/\_]/ then
              biblatexFields.push('date')
              biblatex['date'] = biblatex.delete('year-date')
            else
              biblatexFields.push('year')
              biblatex['year'] = biblatex.delete('year-date')
            end
          end
        end
        biblatex['title'] = '"'+biblatex['title']+'"'
        options['biblatex'] = biblatex
        options['title']    = biblatex['title']

        options['path'] = 'cite/'+citation2urlBase(biblatex['citekey'])+'.md'
        if !File.exists?(options['path']) then
          siteOpts = Jekyll.configuration(options)
          site = Jekyll::Site.new(siteOpts)
          Page.new(site, options).write
         end
        system("nano +16 #{options['path']}")
      else
        system("nano +16 #{citationPath}")
      end
    end

    def checkForAuthorSurName(surname)
      possibleAuthors = Dir.glob("author/*/*#{surname}*").sort;
      possibleAuthors.reject! { | anAuthor | anAuthor =~ /Citations\.md$/ }
      return 'new' if possibleAuthors.empty?

      puts "\nDo you want to use one of these existing authors?"
      possibleAuthors.size.times do | i |
        puts "#{(i+1)}: #{possibleAuthors[i]}"
      end
      index = Readline.readline( "index (or return to add new author): ", true)
      puts ""
      index = index.to_i
      return possibleAuthors[index-1] if (0 < index) &&
        (index < possibleAuthors.size+1)

      return 'new'
    end

    def addAuthor(options)
      require 'pp'
      options["source"]   = '.'
      options["destination"] = '_site'
      options['template'] = 'author'
      options['type']     = 'author'
      options['layout']   = 'author'
      options['surname'] =
        Readline.readline( "Last name: ", true) unless
        options.has_key?('surname')
      return nil if options['surname'].empty?

      authorPath = checkForAuthorSurName(options['surname'])
      if authorPath == 'new' then
        options['firstname'] =
          Readline.readline( "First Name: ", true) unless
          options.has_key?('firstname')
        options['von'] =
          Readline.readline( "Von part: ", true) unless
          options.has_key?('von')
        options['jr'] =
          Readline.readline( "Jr/Sr part: ", true) unless
          options.has_key?('jr')
        options['institue'] =
          Readline.readline( "Institute: ", true) unless
          options.has_key?('institue')
        options['email'] =
          Readline.readline( "Email: ", true) unless
          options.has_key?('email')
        options['url'] =
          Readline.readline( "URL: ", true) unless
          options.has_key?('url')
        options['cleanname'] = 
          (options['von'] + ' ' + 
           options['surname'] + ' ' + 
           options['jr'] + ', ' + 
           options['firstname']).gsub(/\s+/,' ').gsub(/\s+,/,',').strip
        options['title'] = options['cleanname']
          
        options['path'] = author2urlBase(options['cleanname'])+'.md'
        pp options
        if !File.exists?(options['path']) then
          siteOpts = Jekyll.configuration(options)
          site = Jekyll::Site.new(siteOpts)
          Page.new(site, options).write
         end
        system("nano +16 #{options['path']}")
      else
        system("nano +16 #{authorPath}")
        authorData = loadJekyllDataFile(authorPath)
        options['title'] = authorData[:metaData]['title']
      end
      return options['title']
    end

  end

  class NewCitation < NewCommand
    extend Jekyll::Citation2UrlFilter
    extend Jekyll::Author2UrlFilter
    extend RefCommandUtils

    def self.init_with_command(c)
      c.command(:cite) do |c|
        c.syntax 'cite <citationType> [options]'
        c.description 'Add a new citation to your references subSite.'
        c.option 'title', '-t', '--title TITLE', 'String to be added as the title in the YAML front-matter.'
        NewCommand.add_page_options c
        NewCommand.add_common_options c

        c.action do |args, options|
          biblatexTypes = SafeYAML.load_file('_data/biblatexTypes.yml')
          typesStringArray = Array.new
          biblatexTypes.keys.sort.each do | aKey |
            aValue = biblatexTypes[aKey]
            aliases = ""
            aliases = aValue['aliases'] if aValue.has_key?('aliases')
            typesStringArray.push("#{aKey} #{aliases}")
          end
          typesString = typesStringArray.join("\n\t")
          if args.empty? then
            c.logger.error "Please choose one of the following types:"
            puts "\t"+typesString
            puts c
          else
            citationType = args.first
            if !biblatexTypes.has_key?(citationType) then
              c.logger.error "Unknown citation type [#{citationType}]"
              c.logger.error "Please choose one of the following types:"
              c.logger.error "\t"+typesString
              puts c
            else
              addCitation(options, citationType, biblatexTypes)
            end
          end
        end
      end
    end
  end

  class NewAuthor < NewCommand
    extend Jekyll::Author2UrlFilter
    extend RefCommandUtils

    def self.init_with_command(c)
      c.command(:author) do |c|
        c.syntax 'author [options]'
        c.description 'Add a new author to your references subSite.'
        c.option 'title', '-t', '--title TITLE', 'String to be added as the title in the YAML front-matter.'
        NewCommand.add_page_options c
        NewCommand.add_common_options c

        c.action do |args, options|
          addAuthor(options)
        end
      end
    end
  end
end
