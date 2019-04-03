#coding: UTF-8

module Octopress

  module PropagateRefsCommandUtils

    def cleanUpCitation(oldCitation)
      newCitation = Hash.new
      newCitation[:changed] = true
      oldCitation.each_key do | aKey | 
        newCitation[aKey] = oldCitation[aKey].clone
      end
      newCitation[:content] = 
        oldCitation[:content].split(/^[ \t]*###+[ \t]*[Ww]orking[ \t]*[Nn]otes[ \t]*###+[ \t]*$/)[0]

      newCitation[:metaData] = Hash.new
      oldCitation[:metaData].each_key do | aKey |
        newCitation[:metaData][aKey] = oldCitation[:metaData][aKey].clone
      end

      newCitation[:metaData]['biblatex'] = Hash.new
      oldCitation[:metaData]['biblatex'].each_key do | aKey |
        next if aKey == 'docType'
        next if aKey == 'visibility'
        newCitation[:metaData]['biblatex'][aKey] = 
          oldCitation[:metaData]['biblatex'][aKey]
        newCitation[:metaData]['biblatex'][aKey] = 
          oldCitation[:metaData]['biblatex'][aKey].clone unless
          oldCitation[:metaData]['biblatex'][aKey].nil? ||
          oldCitation[:metaData]['biblatex'][aKey].is_a?(Fixnum) ||
          oldCitation[:metaData]['biblatex'][aKey].is_a?(Array)
        if oldCitation[:metaData]['biblatex'][aKey].is_a?(Array) then
          newCitation[:metaData]['biblatex'][aKey] = Array.new
          oldCitation[:metaData]['biblatex'][aKey].each do | aValue |
            newCitation[:metaData]['biblatex'][aKey].push(aValue.clone)
          end
        end  
      end
      return newCitation
    end

    def addAuthors(authors, biblatex)
      propagateTo = biblatex['visibility']
      ['author', 'bookauthor', 'commentator',
       'editor', 'editora', 'editorb', 'editorc',
       'holder', 'translator']. each do | aNameField |
        if biblatex.has_key?(aNameField) then
          biblatex[aNameField].each do | aName |
            authors[aName] = propagateTo
          end
        end
      end
    end

    def propagateCitations
      authors = Hash.new
      recursivelyWalkDir('cite', '') do | aCitation |
        next unless aCitation[:metaData].has_key?('biblatex')
        biblatex = aCitation[:metaData]['biblatex']
        if biblatex.has_key?('visibility') then
          addAuthors(authors, biblatex)
          biblatex['visibility'].each do | aPropagateToSite |
            puts "    Propagating [#{aCitation[:file]}] to [#{aPropagateToSite}]"# unless @options.has_key?('quite')
            saveJekyllDataFile(cleanUpCitation(aCitation), '../../'+aPropagateToSite+'/refs')
          end
        end
      end
      return authors
    end

    def cleanUpAuthor(oldAuthor)
      newAuthor = Hash.new
      newAuthor[:changed] = true
      oldAuthor.each_key do | aKey |
        newAuthor[aKey] = oldAuthor[aKey].clone
      end
      newAuthor[:content] =
        newAuthor[:content].split(/^[ \t]*###+[ \t]*[Ww]orking[ \t]*[Nn]otes[ \t]*###+[ \t]*$/)[0]

      newAuthor[:metaData] = Hash.new
      oldAuthor[:metaData].each_key do | aKey |
        newAuthor[:metaData][aKey] = oldAuthor[:metaData][aKey].clone
      end

      newAuthor[:metaData]['biblatex'] = Hash.new
      oldAuthor[:metaData]['biblatex'].each_key do | aKey |
        newAuthor[:metaData]['biblatex'][aKey] =
          oldAuthor[:metaData]['biblatex'][aKey]
        newAuthor[:metaData]['biblatex'][aKey] =
          oldAuthor[:metaData]['biblatex'][aKey].clone unless
          oldAuthor[:metaData]['biblatex'][aKey].nil? ||
          oldAuthor[:metaData]['biblatex'][aKey].is_a?(Fixnum) ||
          oldAuthor[:metaData]['biblatex'][aKey].is_a?(Array)
        if oldAuthor[:metaData]['biblatex'][aKey].is_a?(Array) then
          newAuthor[:metaData]['biblatex'][aKey] = Array.new
          oldAuthor[:metaData]['biblatex'][aKey].each do | aValue |
            newAuthor[:metaData]['biblatex'][aKey].push(aValue.clone)
          end
        end
      end
      return newAuthor
    end

    def propagateAuthors(authors)
      recursivelyWalkDir('author', '') do | anAuthor |
        next unless anAuthor[:metaData].has_key?('biblatex')
        next unless authors.has_key?(anAuthor[:metaData]['title'])
        authors[anAuthor[:metaData]['title']].each do | aPropagateToSite |
          puts "    Propagating [#{anAuthor[:file]}] to [#{aPropagateToSite}]" # unless @options.has_key?('quite')
          saveJekyllDataFile(cleanUpAuthor(anAuthor), '../../'+aPropagateToSite+'/refs')
        end
      end
    end

  end

  class PropagateRefsCommand < Command
    extend PropagateRefsCommandUtils
    require 'jekyllWalker'
    extend JekyllWalker

    def self.init_with_program(p)
      p.command(:propagate) do | c |
        c.alias :prop
        c.syntax 'propagate'
        c.description 'Propagates references to selected external websites'
        c.option 'quite',   '-q', '--quite',   'keep quite about loading/writing'
        c.option 'verbose', '-v', '--verbose', 'report when we load/write files'

        c.action do | args, options |
          options['quite'] = true unless options['verbose']
          @options = options
          propagateAuthors(propagateCitations)
        end
      end
    end
  end
end
