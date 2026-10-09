# Writes packages.yml with the GitHub repositories tagged cuis-smalltalk-package, grouped by package
# name and curated by packages-config.yml.
# Run it from the repository root. GITHUB_TOKEN, when set, raises the GitHub API rate limit.

require "json"
require "net/http"
require "yaml"

QUERY = "topic:cuis-smalltalk-package fork:true"
ORGANIZATION = "Cuis-Smalltalk"
GENERIC_TOPICS = ["cuis", "cuis-smalltalk", "cuis-smalltalk-package", "smalltalk"]
PAGE_SIZE = 100
CONFIG = YAML.load_file("_data/packages-config.yml")

def search(page = 1)
  url = URI("https://api.github.com/search/repositories?" + URI.encode_www_form(q: QUERY, per_page: PAGE_SIZE, page: page))
  headers = ENV["GITHUB_TOKEN"] ? { "Authorization" => "Bearer #{ENV["GITHUB_TOKEN"]}" } : {}
  results = JSON.parse(Net::HTTP.get(url, headers))
  raise "Incomplete search results" if results["incomplete_results"]
  repos = results["items"]
  repos.size < PAGE_SIZE ? repos : repos + search(page + 1)
end

def excluded?(repo)
  CONFIG["excluded"].include?(repo["full_name"]) || CONFIG["excluded"].include?(repo["owner"]["login"])
end

def from_organization?(repo)
  repo["owner"]["login"] == ORGANIZATION
end

def featured?(repo)
  CONFIG["featured"].include?(repo["full_name"])
end

def package_name(repo)
  repo["name"].sub(/\ACuis-(Smalltalk-)?/i, "")
end

def source_data(repo)
  description = repo["description"].to_s.strip
  {
    "repo" => repo["full_name"],
    "url" => repo["html_url"],
    "official" => from_organization?(repo),
    "pushed_at" => repo["pushed_at"],
    "description" => (description unless description.empty?),
  }
end

def package_data(package)
  official, others = package.partition { |repo| from_organization?(repo) }
  featured, others = others.partition { |repo| featured?(repo) }
  {
    "name" => package_name(package.first),
    "featured" => package.any? { |repo| featured?(repo) },
    "official" => official.any?,
    "pushed_at" => package.first["pushed_at"],
    "topics" => package.flat_map { |repo| repo["topics"] }.uniq - GENERIC_TOPICS,
    "sources" => (official + featured + others).map { |repo| source_data(repo) },
  }
end

# Most recently pushed first. Packages keep that order, and so do their repositories after the official and featured ones.
repos = search.reject { |repo| excluded?(repo) }.sort_by { |repo| repo["pushed_at"] }.reverse
packages = repos.group_by { |repo| package_name(repo).downcase }.values

File.write("_data/packages.yml", YAML.dump(packages.map { |package| package_data(package) }, line_width: -1))
