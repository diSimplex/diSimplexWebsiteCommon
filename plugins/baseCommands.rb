# This is a hack/monkey-patch on Octopress's 3.0.0 implementation of 
# the new command. Our intention is to make adding new types of 
# posts/pages as easy/modular as possible.

require 'readline'
require 'yaml'

module Mercenary
  Presenter.class_eval do
    def subcommands_presentation
      return nil unless command.commands.size > 0
      command.commands.keys.sort.collect{ |k| command.commands[k]}.uniq.map(&:summarize).join("\n")
    end
  end
end

module Jekyll
  module Commands
    New.class_eval do
      def self.init_with_program(p)
      end
    end
  end
end

module Octopress

  # The following has been taken from 
  # octopress-3.0.0.rc.31/lib/octopress/command.rb
  #
  class NewCommand
    def self.inherited(base)
      subclasses << base
    end

    def self.subclasses
      @subclasses ||= []
    end

    def init_with_command(c)
      raise NotImplementedError.new("")
    end

    def self.createFileNameFromTitle(options)
      options['title'].downcase.gsub(/\W+/,'-').gsub(/\-+/,'-').sub(/^\-/,'').sub(/\-$/,'') + '.md'
    end

    # Taken from octopress-3.0.0.rc.31/lib/octopress/commands/helper.rb
    #
    def self.add_page_options(c)
      c.option 'date',     '-d', '--date DATE', "Use 'now' or a String that is parseable by Time#parse."
      c.option 'template', '-tm', '--template PATH', "New #{c.name.to_s} from a template."
      c.option 'lang',     '-l', '--lang LANGUAGE', "Set a #{c.name.to_s} language (e.g. en, it) for multi-language sites."
      c.option 'force',    '-f', '--force', 'Overwrite file if it already exists'
    end

    # Taken from octopress-3.0.0.rc.31/lib/octopress/commands/helper.rb
    #
    def self.add_common_options(c)
      c.option 'config',    '-c', '--config <CONFIG_FILE>[,CONFIG_FILE2,...]', Array, 'Custom Jekyll configuration file'
    end

  end

  # The following has been adapted from
  # octopress-3.0.0.rc.31/lib/octopress/commands/new.rb
  # 
  class Create < Command
    def self.init_with_program(p)
      p.command(:create) do |c|
        c.syntax 'create <PATH>'
        c.description 'Creates a new site with Jekyll and Octopress scaffolding at the specified path.'
        c.option 'force', '-f', '--force', 'Force creation even if path already exists.'
        c.option 'blank', '-b', '--blank', 'Creates scaffolding but with empty files.'
        
        c.action do |args, options|
          if args.empty?
            c.logger.error "You must specify a path."
            puts c
          else
            Jekyll::Commands::New.process(args, options)
            Octopress::Scaffold.new(args, options).write
          end
        end
      end
    end
  end

  New.class_eval do
    def self.init_with_program(p)
      p.command(:new) do |c|
        c.syntax 'new <document type>'
        c.description 'Creates a new document.'
        c.option 'force', '-f', '--force', 'Force creation even if path already exists.'
        
        c.action do |args, options|
          c.logger.error "You must specify a type of document to create."
          puts c
        end

        # Adapted from jekyll-2.5.3/bin/jekyll
        #
        Octopress::NewCommand.subclasses.each { |nsc| nsc.init_with_command(c) }

      end
    end
  end

  class NewPage < NewCommand
    def self.init_with_command(c)
      c.command(:page) do |c|
        c.syntax 'page <PATH> [options]'
        c.description 'Add a new page to your Jekyll site.'
        c.option 'title', '-t', '--title TITLE', 'String to be added as the title in the YAML front-matter.'
        NewCommand.add_page_options c
        NewCommand.add_common_options c

        c.action do |args, options|
          if args.empty?
            c.logger.error "Please choose a path"
            puts c
          else
            options['title'] =
              Readline.readline( "Title: ", true) unless
              options.has_key?('title')
            options['path'] = args.first + '/' + createFileNameFromTitle(options)
            Page.new(Octopress.site(options), options).write unless 
              File.exists?(options['path'])
            system("nano +10 #{options['path']}")
          end
        end
      end
    end
  end

# We implement the new post command in the blog subsite using OUR rules
#
#  class NewPost < NewCommand
#    def self.init_with_command(c)
#      puts "Initializing using NEW new post command"
#      c.command(:post) do |c|
#        c.syntax 'post <TITLE> [options]'
#        c.description 'Add a new post to your Jekyll site.'
#        NewCommand.add_page_options c
#        c.option 'slug', '-s', '--slug SLUG', 'Use this slug in filename instead of sluggified post title.'
#        c.option 'dir', '-d', '--dir DIR', 'Create post at _posts/DIR/.'
#        NewCommand.add_common_options c
#
#        c.action do |args, options|
#          if args.empty?
#            c.logger.error "Please choose a title."
#            puts c
#          else
#            options['title'] = args.join(" ")
#            Post.new(Octopress.site(options), options).write
#          end
#        end
#      end
#    end
#  end

# We DO NOT use drafts since we have internal==draft and 
# external==published websites
#
#  class NewDraft < NewCommand
#    def self.init_with_command(c)
#      puts "Initializing using NEW new draft command"
#      c.command(:draft) do |c|
#        c.syntax 'draft <TITLE> [options]'
#        c.description 'Add a new draft post to your Jekyll site.'
#        NewCommand.add_page_options c
#        c.option 'slug', '-s', '--slug SLUG', 'Use this slug in filename instead of sluggified post title.'
#        NewCommand.add_common_options c
#
#        c.action do |args, options|
#          if args.empty?
#            c.logger.error "Please choose a title"
#            puts c
#          else
#            options['title'] = args.join(" ")
#            Draft.new(Octopress.site(options), options).write
#          end
#        end
#      end
#    end
#  end

  class GitCommand < Command
    def self.init_with_program(p)
      p.command(:git) do |c|
        c.syntax 'git'
        c.description 'Uses Git to add, commit and then push all recent changes'

        c.action do |args, options|
          begin
            puts ""
            system('git status')
            commitMessage = Readline.readline( "\n^C to abort\ncommit message: ", true)
            system('git add -A')
            system("git commit -m \"#{commitMessage}\"")
            system('git push')
          rescue Exception
            puts ""
          end
        end
      end
    end
  end

  class StageCommand < Command
    def self.init_with_program(p)
      p.command(:stage) do |c|
        c.syntax 'stage'
        c.description 'Stage your Octopress site.'
        c.action do | args, options |
          options[:config_file] = '_stage.yml' unless options.has_key?(:config_file)
          options[:site_dir]    = '_site' unless options.has_key?(:site_dir)
          Octopress::Deploy.push(options)
        end
      end
    end
  end

  class CleanCommand < Command
    require 'xapianBase'
    extend XapianBase

    def self.init_with_program(p)
      p.command(:clean) do |c|
        c.syntax 'clean'
        c.description 'Removes the _site and xapian directories'

        c.action do |args, options|
          begin
            puts ""
            system('rm -rf _site xapian')
            puts "Recreating Xapian"
            setupXapian(Octopress.site)
            closeDownXapian
          rescue Exception
            puts ""
          end
        end
      end
    end
  end

  class IndexCommand < Command
    require 'jekyllWalker'
    extend JekyllWalker

    require 'xapianBase'
    extend XapianBase

    XAPIAN_LAST_REINDEX = "xapian/lastReIndex"

    def self.init_with_program(p)
      p.command(:index) do |c|
        c.syntax 'index'
        c.alias :idx
        c.description 're-Build the Xapian indexes'
        c.option 'quite',   '-q', '--quite',   'keep quite about loading/writing'
        c.option 'verbose', '-v', '--verbose', 'report when we load/write files'

        c.action do | args, options |
          options['quite'] = true unless options['verbose']
          @options = options
          require 'xapianIndexer'
          extend XapianIndexer

          puts ""
          system('rm -rf xapian')
          puts "Recreating Xapian"
          setupXapian(Octopress.site)
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

      p.command(:reindex) do |c|
        c.syntax 'reindex'
        c.description 'Removes the xapian directories'
        c.action do | args, options |
          begin
            puts ""
            system('rm -rf xapian')
            puts "Recreating Xapian indexes"
            setupXapian(Octopress.site)
            closeDownXapian
          rescue Exception
            puts ""
          end
        end
      end
    end
  end # IndexCommand

#  class BuildCommand < Command
#    require 'jekyllWalker'
#    extend JekyllWalker
#
#    LAST_BUILD = ".lastBuild"
#
#    def self.init_with_program(p)
#      p.commands.delete(:build) if p.commands.has_key?(:build)
#      p.commands.delete(:b)     if p.commands.has_key?(:b)
#      p.command(:build) do |c|
#        c.syntax 'build'
#        c.description 'my build command'
#        c.action do | args, options |
#          require 'builder'
#          extend Builder
#
#          recursivelyWalkDir(buildList(), LAST_BUILD) do | someJekyllData |
#            someJekyllData[:url] =
#              someJekyllData[:file].sub(/\.md$/,'.html').sub(/^\.\//,'')
#            buildPage(someJekyllData)
#          end
#        end
#      end
#    end
#  end

end
