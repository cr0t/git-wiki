# This file is used by Rack-based servers to start the application.

require 'git-wiki'
run GitWiki.new(File.expand_path(File.dirname(__FILE__), "~/wiki"), ".markdown", "Home")
