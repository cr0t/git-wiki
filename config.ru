# This file is used by Rack-based servers to start the application.

require "git-wiki"
require "yaml"

CONFIG = YAML.load(File.read(File.expand_path("~/wiki.yaml", __FILE__)))

run GitWiki.new(File.expand_path(File.dirname(__FILE__), "~/wiki"), ".markdown", "Home")
