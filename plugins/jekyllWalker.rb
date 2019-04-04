# encoding: UTF-8

# This is a collection of library functions which can be used to help 
# walk over all author/citation entries, make systematic changes and 
# the write out the results.

require 'fileutils'
require 'yaml'
require 'safe_yaml/load'

module JekyllWalker

  WALKER_DIR = '_walkerResults'

  def reportEncoding(aValue)
    aValue.each_pair do | key, value |
      if value.is_a?(Hash) then
        value.each_pair do | subKey, subValue |
          if subValue.is_a?(Hash) then
            subValue.each_pair do | subSubKey, subSubValue |
              if subSubValue.is_a?(String) then
                puts "#{key}::#{subKey}::#{subSubKey} #{subSubValue.encoding}"
              elsif subSubValue.is_a?(Array) then
                subSubValue.each do | aSubSubSubValue |
                  if aSubSubSubValue.is_a?(String) then
                    puts "#{key}::#{subKey}::#{subSubKey}::[#{aSubSubSubValue}] #{aSubSubSubValue.encoding}"
                  end
                end
              end
            end
          elsif subValue.is_a?(Array) then
            subValue.each do | subSubValue |
              if subSubValue.is_a?(String) then
                puts "#{key}::#{subKey} #{subSubValue.encoding}"
              end
            end
          elsif subValue.is_a?(String) then
            puts key.to_s+'::'+subKey.to_s+' '+subValue.encoding.to_s
          end
        end
      elsif value.is_a?(Array) then
        value.each do | subValue |
          if subValue.is_a?(String) then
            puts key.to_s+' '+subValue.encoding.to_s
          end
        end
      elsif value.is_a?(String) then
        puts key.to_s+' '+value.encoding.to_s
      end
    end
  end

  def loadJekyllDataFile(aJekyllDataFile)
    puts '  Loading: '+aJekyllDataFile unless @options.has_key?('quite')
    jekyllData = {
      file: aJekyllDataFile,
      url: aJekyllDataFile.sub(/\.[^\.]+$/,'.html')
    }
    content = "---\n---\n"
    content = File.read(aJekyllDataFile) if File.readable?(aJekyllDataFile)
#    puts content.encoding
    jekyllData[:content] = content
    if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
      jekyllData[:metaData] = SafeYAML.load($1)
      jekyllData[:metaData] = Hash.new if jekyllData[:metaData].nil?
      jekyllData[:content].sub!(/\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m, '')
    end
#    reportEncoding(jekyllData)
    jekyllData
  end

  def saveHash(jFile, aKey, indent, aHash)
#    puts "saveHash: [#{aKey}] [#{indent}]"
    aKey = '"'+aKey+'"' if aKey.downcase == "no" or aKey.downcase == "on"
    aYamlKey = indent+aKey
    aYamlKey = aYamlKey+':' unless aKey =~ /^\s*-\s*$/
    aYamlKey = aYamlKey+' '
    if aHash.empty? then
      jFile.puts aYamlKey+'{}'
      return
    end
    jFile.puts aYamlKey
    aHash.each_key.sort.each do | aSubKey |
      aValue = aHash[aSubKey]
      if aValue.is_a?(Hash) then
        saveHash(jFile, aSubKey, indent+'  ', aValue)
      elsif aValue.is_a?(Array) then
        saveArray(jFile, aSubKey, indent+'  ', aValue)
      else
        saveString(jFile, aSubKey, indent+'  ', aValue.to_s)
      end
    end
  end

  def saveArray(jFile, aKey, indent, anArray)
#    puts "saveArray: [#{aKey}] [#{indent}]"
    aKey = '"'+aKey+'"' if aKey.downcase == "no" or aKey.downcase == "on"
    aYamlKey = indent+aKey
    aYamlKey = aYamlKey+':' unless aKey =~ /^\s*-\s*$/
    aYamlKey = aYamlKey+' '
    if anArray.empty? then
      jFile.puts aYamlKey+'[]'
      return
    end
    jFile.puts aYamlKey
    anArray.each do | aValue |
      if aValue.is_a?(Hash) then
        saveHash(jFile, '-', indent+'  ', aValue)
      elsif aValue.is_a?(Array) then
        saveArray(jFile, '-', indent+'  ', aValue)
      else
        saveString(jFile, '-', indent+'  ', aValue.to_s)
      end
    end
  end

  def recodeString(aString)
#    puts aString.encoding.to_s
#    puts '['+aString+']'
     #
     #  WHY DID I DO THIS????
     #
#    aString.encode!( "ASCII-8BIT" , {
#      :invalid=>:replace, 
#      :undef=>:replace,
#      :replace=>'?',
#      :universal_newline=>true})
#    aString.gsub!(/[\000-\011\013-\037\177-\377]/,'?')
    #
    # ensure any Yaml-nasty characters are escaped!
    #
    aString.gsub!(/\\+([\'\w])/,'\\\\\\\\\1')
    aString.gsub!(/\\*\"/,'\"')
#    puts aString.encoding.to_s
#    puts '['+aString+']'
  end

  def breakLongLine(jFile, indent, aString) 
    stringLine = indent.dup
    newLineLength = indent.length+1
    aString.split.each do | aWord |
      stringLine += ' '+aWord
      newLineLength += aWord.length+1
      if 65 < newLineLength then
        jFile.puts stringLine
        stringLine = indent.dup
        newLineLength = indent.length+1
      end
    end
    jFile.puts stringLine if (3 < stringLine.length)
  end

  def saveString(jFile, aKey, indent, aString)
#    puts "saveString [#{aKey}] [#{indent}] [#{aString}]"
    aKey = '"'+aKey+'"' if aKey.downcase == "no" or aKey.downcase == "on"
    aYamlKey = indent+aKey
    aYamlKey = aYamlKey+':' unless aKey =~ /^\s*-\s*$/
    aYamlKey = aYamlKey+' '
    if aString.nil? then
      jFile.puts aYamlKey
      return
    end
    recodeString(aString)
    if aString =~ /\n/ then
      jFile.puts aYamlKey+'|'
      aString.each_line do | aLine |
        aLine.chomp!
        if (65 < aLine.length) then
          breakLongLine(jFile, indent+' ', aLine)
        else 
          jFile.puts indent+'  '+aLine
        end
      end
    elsif 65 < aString.length && aString !~ /^http/ then
      jFile.puts aYamlKey+'|'
      breakLongLine(jFile, indent+' ', aString)
    elsif aString =~ /[\'\:\{\}\[\]\&\^\$]/ or 
          aString =~ /^\s*\?/ or
          aString =~ /^\d+$/ or
          aString.downcase == "no" or
          aString.downcase == "on" then
      jFile.puts aYamlKey+'"'+aString+'"'
    else
      jFile.puts aYamlKey+aString
    end
  end

#  def saveJekyllBiblatexData(jFile, biblatexData)
#    return if biblatexData.nil?
#    jFile.puts 'biblatex:'
#    biblatexData.each_key.sort.each do | aKey |
#      aValue = biblatexData[aKey]
#      yamlKey = '  '+aKey+': '
#      if aValue.is_a?(Hash) then
#        saveHash(jFile, yamlKey, '    ', aValue)
#      elsif aValue.is_a?(Array) then
#        saveArray(jFile, yamlKey, '  - ', aValue)
#      else
#        saveString(jFile, yamlKey, aValue.to_s)
#      end
#    end
#  end

  def saveJekyllMetaData(jFile, someMetaData)
    #
    # take off the "standard" fields so we can control the saving order
    #
    biblatexData = someMetaData.delete('biblatex')
    layout       = someMetaData.delete('layout')
    title        = someMetaData.delete('title')
    saveString(jFile, 'layout', '', layout)
    saveString(jFile, 'title', '', title)
    saveHash(jFile, 'biblatex', '',  biblatexData) unless biblatexData.nil?
    #
    # now save everything else
    #
    someMetaData.each_key.sort.each do | aKey |
      aValue = someMetaData[aKey]
      if aValue.is_a?(Hash) then
        saveHash(jFile, aKey, '', aValue)
      elsif aValue.is_a?(Array) then
        saveArray(jFile, aKey, '- ', aValue)
      else
        saveString(jFile, aKey, '', aValue.to_s)
      end
    end
    #
    # now replace the "standard" fields
    #
    someMetaData['layout']   = layout
    someMetaData['title']    = title
    someMetaData['biblatex'] = biblatexData
  end

  def saveJekyllDataFile(someJekyllData, walkerDir = WALKER_DIR)
    return unless someJekyllData.has_key?(:changed)
#    reportEncoding(someJekyllData)
    newFileName = walkerDir+'/'+someJekyllData[:file]
    puts '    Saving: '+newFileName unless @options.has_key?('quite')
    FileUtils.mkdir_p(File.dirname(newFileName))
    File.open(newFileName, 'w') do | jFile |
      jFile.puts "---"
      saveJekyllMetaData(jFile, someJekyllData[:metaData])
      jFile.puts "---"
      if someJekyllData.has_key?(:content) &&
         !someJekyllData[:content].nil? then
        recodeString(someJekyllData[:content])
        jFile.puts someJekyllData[:content]
      end
    end
  end

  def walkDir(baseDir, lastWalkFileName, &aBlock)
    if ! aBlock then
      puts "WARNING no block provided to walk #{baseDir}!"
      puts "        doing nothing...."
      return
    end

    baseDir = [ baseDir ] unless baseDir.is_a?(Array)

    baseDir.each do | aDir |
      puts "Walking through #{aDir}"
      Dir.glob(aDir+'/*.md').sort.each do | aJekyllFileName |
        next if FileUtils.uptodate?(lastWalkFileName, [ aJekyllFileName ])
        aJekyllFile = loadJekyllDataFile(aJekyllFileName)
        aBlock.call(aJekyllFile)
        saveJekyllDataFile(aJekyllFile)
      end
    end
  end

  def recursivelyWalkDir(baseDir, lastWalkFileName, &aBlock)
    if ! aBlock then
      puts "WARNING no block provided to walk #{baseDir}!"
      puts "        doing nothing...."
      return
    end

    baseDir = [ baseDir ] unless baseDir.is_a?(Array)

    baseDir.each do | aDir |
      puts "Walking through #{aDir}"
      #
      # walk all directories depth first... 
      # ... ignoring non directories
      #
      Dir.glob(aDir+'/*').sort.each do | aJekyllFileName |
        next if aJekyllFileName =~ /$\.+$/
        next if aJekyllFileName =~ /\/_[^\/]+$/
        next if aJekyllFileName =~ /\/xapian$/
        if File.directory?(aJekyllFileName) then
          recursivelyWalkDir(aJekyllFileName, lastWalkFileName, &aBlock)
        end
      end
      #
      # now that we have walked all directories
      # ... we walk all of the non directories
      #
      Dir.glob(aDir+'/*').sort.each do | aJekyllFileName |
        next if aJekyllFileName =~ /$\.+$/
        next if aJekyllFileName =~ /\/_[^\/]+$/
        next if aJekyllFileName =~ /\/xapian$/
        if not File.directory?(aJekyllFileName) then
          next unless aJekyllFileName =~ /\.md$/
          next if FileUtils.uptodate?(lastWalkFileName, [ aJekyllFileName ])
          aJekyllFile = loadJekyllDataFile(aJekyllFileName)
          aBlock.call(aJekyllFile)
          saveJekyllDataFile(aJekyllFile) if @options.has_key?('save')
        end
      end
    end
  end


end
