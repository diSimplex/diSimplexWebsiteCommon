# diSimplex common "bin" tools

This "bin" directory contains our slight modification to the Jekyll tool to 
enable the diSimplex website to be built out of **multiple** sub-websites.

Hence the name "mjekyll" as opposed to "jekyll".

At the moment our mjekyll tool uses the following Ruby gems:

    jekyll-3.8.5
    jekyll-sass-converter-1.5.2
    jekyll-watch-2.0.0

    liquid-4.0.0

    mercenary-0.3.6

    nokogiri-1.10.1

    octopress-3.0.11
    octopress-deploy-1.3.0
    octopress-escape-code-2.1.1
    octopress-hooks-2.6.2

    rouge-3.2.1

    sass-3.5.7
    sass-listen-4.0.0

at the specified version. (Newer versions may or may not work at this 
time).

For the xapian based indexing we also need either

    sudo apt-get install libxapian-dev
    sudo gem install xapian

OR

    sudo apt-get install ruby-xapian


