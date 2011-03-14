#!/usr/bin/env rackup
require File.dirname(__FILE__) + "/git-wiki"

run GitWiki.new(File.expand_path(File.dirname(__FILE__), "~/wiki"), ".markdown", "Home")
