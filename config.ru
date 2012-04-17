# This file is used by Rack-based servers to start the application.

require File.dirname(__FILE__) + "/git-wiki"
require "yaml"
require "grit"

$CONFIG = YAML.load(File.read(File.expand_path("~/wiki.yaml", __FILE__)))

unless File.exists? $CONFIG["wiki_repo_path"]
  Dir.mkdir $CONFIG["wiki_repo_path"]
end

begin
  Grit::Repo.new($CONFIG["wiki_repo_path"])
rescue Grit::InvalidGitRepositoryError
  if `which git`.length > 0
    `cd #{$CONFIG["wiki_repo_path"]} && git init`
  else
    raise "Unknown platform, there is no git binary, please init git repo in the given wiki_repo_path"
  end
end

run GitWiki.new($CONFIG["wiki_repo_path"], ".markdown", "Home")
