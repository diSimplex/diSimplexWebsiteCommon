require 'xapian'

module XapianBase

    def setupXapian(site)
      puts "Opening Xapian"

      # setup Xapian database
      @xapianDB = Xapian::WritableDatabase.new('xapian',
        Xapian::DB_CREATE_OR_OVERWRITE)

      @xapianIndexer         = Xapian::TermGenerator.new()
      @xapianIndexer.stemmer = Xapian::Stem.new("english")

      @stopWords = Hash.new
      @stopWords = site.data['stopWords'] if site.data.has_key?('stopWords')
#      @wordFreq  = Hash.new

      @xapianDocId = Hash.new
      @xapianDocId = YAML.load(File.read('xapian/_xapianDocIds.yml')) if
        File.exists?('xapian/_xapianDocIds.yml')

    end

    def closeDownXapian

      puts "Closing Xapian"

#      File.open('xapian/_wordFreq.yml', 'w') do | ymlFile |
#        ymlFile.write(YAML.dump(@wordFreq))
#      end

      File.open('xapian/_xapianDocIds.yml', 'w') do | ymlFile |
        ymlFile.write(YAML.dump(@xapianDocId))
      end

      @xapianDB.commit
      @xapianDB.close

      puts "Closed Xapian"

    end

    def removeStopWords(aStr)
      aStoppedStr = aStr.gsub(/\W+/,' ')
      aStoppedStr.gsub!(/\b\w+\b/) do | aWord |
        dcWord = aWord.downcase
        stopWord = false
        stopWord = (aWord.size < 4)            unless stopWord
        stopWord = (aWord =~ /^\d+$/)          unless stopWord
#        if !stopWord then
#          @wordFreq[dcWord] = 0 unless @wordFreq.has_key?(dcWord)
#          @wordFreq[dcWord] += 1
#        end
        stopWord ? '' : aWord
      end
      aStoppedStr
    end
  

end
