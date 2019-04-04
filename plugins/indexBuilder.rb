# This ruby based Jekyll plugin provides an alphbetical index page builder

module IndexBuilder 

  def addIndexItem(index, indexKey, key, url, linkText, auxText = "")
    index[indexKey] = Hash.new unless index.has_key?(indexKey)
    index[indexKey][key] = {
      'url'      => url,
      'linkText' => linkText,
      'auxText'  => auxText
    }
  end

  def addDirIndexPages(basePath, baseTitle, page)
    fileName  = File.basename(page[:file], '.md')
    fileUrl   = page[:file].gsub(/\.md/, '.html')
    pathDirs  = fileUrl.split(/\//)
    lastPath = pathDirs.shift
    while !pathDirs.empty? do
      aDir = pathDirs.shift
      curDirIndexPath = "#{lastPath}/index.md"
      puts curDirIndexPath
      curDirIndex = loadJekyllDataFile(curDirIndexPath)
      curDirIndex[:metaData]['title']  = lastPath
      curDirIndex[:metaData]['layout'] = 'index'
      curDirIndex[:changed]            = true
      anItem = aDir.gsub(/\.html$/, '')
      addIndexItem(
        curDirIndex[:metaData],
       'index',
       'k'+anItem,
       lastPath+'/'+aDir,
       anItem
      )
      lastPath = lastPath + '/' + aDir
    end
  end

  def addIndexPages(basePath, baseTitle, page)
    fileName       = File.basename(page[:file], '.md')
    oneLetter      = fileName[0]
    twoLetters     = fileName[0..1]
    indexFile      = 'index.md'
    zeroLetterPath = "#{basePath}/#{indexFile}"
    oneLetterPath  = "#{basePath}/#{oneLetter}#{indexFile}"
    twoLetterPath  = "#{basePath}/#{twoLetters}/#{twoLetters}#{indexFile}"

    zeroLetterIndex = loadJekyllDataFile(zeroLetterPath)
    oneLetterIndex  = loadJekyllDataFile(oneLetterPath)
    twoLetterIndex  = loadJekyllDataFile(twoLetterPath)

    zeroLetterIndex[:metaData]['title'] = "#{baseTitle} index"
    zeroLetterIndex[:metaData]['layout'] = "index"
    zeroLetterIndex[:changed] = true

    oneLetterIndex[:metaData]['title']  = "#{baseTitle} '#{oneLetter}' index"
    oneLetterIndex[:metaData]['layout'] = "index"
    oneLetterIndex[:changed] = true

    twoLetterIndex[:metaData]['title']  = "#{baseTitle} '#{twoLetters}' index"
    twoLetterIndex[:metaData]['layout'] = "index"
    twoLetterIndex[:changed] = true

    Dir.glob(basePath+'/*').each do | aFile |
      next if aFile =~ /\.+$/
      next unless File.directory?(aFile)
      dirName = File.basename(aFile)[0]
      indexUrl = basePath+'/'+dirName+'index.html'
      addIndexItem(zeroLetterIndex[:metaData], 'rootIndex',
                   dirName, indexUrl, dirName)
      addIndexItem(oneLetterIndex[:metaData], 'rootIndex',
                   dirName, indexUrl, dirName)
      addIndexItem(twoLetterIndex[:metaData], 'rootIndex',
                   dirName, indexUrl, dirName)
    end unless zeroLetterIndex.has_key?(:rootIndex) && 
      oneLetterIndex.has_key?(:rootIndex) &&
      twoLetterIndex.has_key?(:rootIndex)
    zeroLetterIndex[:rootIndex] = true
    oneLetterIndex[:rootIndex] = true
    twoLetterIndex[:rootIndex] = true

    Dir.glob(basePath+'/'+oneLetter+'*').each do | aFile |
      next if aFile =~ /\.+$/
      next unless File.directory?(aFile)
      dirName = File.basename(aFile)
      indexUrl = basePath+'/'+dirName+'/'+dirName+'index.html'
      addIndexItem(oneLetterIndex[:metaData], 'index',
                   dirName, indexUrl, dirName)
      addIndexItem(twoLetterIndex[:metaData], 'subIndex',
                   dirName, indexUrl, dirName)
    end unless oneLetterIndex.has_key?(:index) &&
      twoLetterIndex.has_key?(:subIndex)
    oneLetterIndex[:index]    = true
    twoLetterIndex[:subIndex] = true

    if basePath == 'cite' then
      addIndexItem(twoLetterIndex[:metaData], 'index',
                   fileName, page[:url], fileName, page[:metaData]['title'])
    else
      addIndexItem(twoLetterIndex[:metaData], 'index',
                   fileName, page[:url], page[:metaData]['title'])
    end
  end

 def sortKeys(index)
    newIndex = Array.new
    return newIndex if index.nil?
    index.keys.sort.each do | aKey |
      newIndex.push(index[aKey])
    end
    newIndex
  end

  def renderDataFileCache(site)
    puts "Walking through cache (expect #{@jekyllDataFiles.length / 50} dots)"
    count = 0
    @jekyllDataFiles.each_key do | aKey |
      count += 1
      if count.modulo(50) == 0 then
        putc '.'
        $stdout.flush
      end
      page = @jekyllDataFiles[aKey]

      page.delete(:rootIndex)
      page.delete(:index)
      page.delete(:subIndex)
      saveJekyllDataFile(page, '.')

      # This needs to be done AFTER saving
      # since we rebuild the rootIndex/index/subIndex
      # to be arrays for rendering
      #
      if page[:file] =~ /index\.md$/ then
        page[:metaData]['rootIndex'] =
          sortKeys(page[:metaData]['rootIndex'])
        page[:metaData]['index'] =
          sortKeys(page[:metaData]['index'])
        page[:metaData]['subIndex'] =
          sortKeys(page[:metaData]['subIndex'])
      elsif page[:file] =~ /Citations\.md$/ then
        page[:metaData]['citeKeys'] =
          sortKeys(page[:metaData]['citeKeys'])
      end
      puts page[:file]
      renderPage(page, site)

      @jekyllDataFiles.delete(aKey)
    end
    puts ""
  end

end # IndexBuilder

