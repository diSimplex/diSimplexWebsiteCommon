module Jekyll

  module Citation2UrlFilter

    def citation2urlBase(citeKey)
      citeKeyLocal = citeKey.sub(/^[0-9]+[ \t]+/,'')
      "#{citeKeyLocal[0..1]}/#{citeKeyLocal}"
    end

    def citation2url(citeKey)
      '/papers/cite/'+citation2urlBase(citeKey)+'.html'
    end

  end

  module Paper2UrlFilter

    def paper2urlBase(paperName)
      paperFileName = paperName.clone
      paperFileName.gsub!(/[\'\",\. \t\n\r]+/,'-');
      paperFileName.gsub!(/\-+/, '-');
      paperFileName.gsub!(/^\-+/, '');
      paperFileName.gsub!(/\-+$/, '');
      "paper/#{paperFileName[0..1]}/#{paperFileName}"
    end

    def paper2url(paperName)
      '/papers/' + paper2urlBase(paperName)+'.html'
    end

  end

  module Author2UrlFilter

    def author2urlBase(authorName)
      authorFileName = authorName.clone
      authorFileName.gsub!(/[\'\",\. \t\n\r]+/,'-');
      authorFileName.gsub!(/\-+/, '-');
      authorFileName.gsub!(/^\-+/, '');
      authorFileName.gsub!(/\-+$/, '');
      "author/#{authorFileName[0..1]}/#{authorFileName}"
    end

    def author2url(authorName)
      '/papers/' + author2urlBase(authorName)+'.html'
    end

  end

  module Keyword2UrlFilter

    def keyword2urlBase(keywordName)
      keywordFileName = keywordName.clone
      keywordFileName.gsub!(/[\'\",\. \t\n\r]+/,'-');
      keywordFileName.gsub!(/\-+/, '-');
      keywordFileName.gsub!(/^\-+/, '');
      keywordFileName.gsub!(/\-+$/, '');
      "keyword/#{keywordFileName[0..1]}/#{keywordFileName}"
    end

    def keyword2url(keywordName)
      '/papers/' + keyword2urlBase(keywordName)+'.html'
    end

  end

end

Liquid::Template.register_filter(Jekyll::Citation2UrlFilter)
Liquid::Template.register_filter(Jekyll::Author2UrlFilter)
Liquid::Template.register_filter(Jekyll::Keyword2UrlFilter)


