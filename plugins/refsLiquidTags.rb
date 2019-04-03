module Jekyll

  module Citation2UrlFilter

    def citation2urlBase(citeKey)
      citeKeyLocal = citeKey.sub(/^[0-9]+[ \t]+/,'')
      "#{citeKeyLocal[0..1]}/#{citeKeyLocal}"
    end

    def citation2url(citeKey)
      '/refs/cite/'+citation2urlBase(citeKey)+'.html'
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
      '/refs/' + author2urlBase(authorName)+'.html'
    end

  end

end

Liquid::Template.register_filter(Jekyll::Citation2UrlFilter)
Liquid::Template.register_filter(Jekyll::Author2UrlFilter)


