Gem::Specification.new do |s|

  s.name            = 'logstash-filter-cleverxml'
  s.version         = '1.0.0'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "Takes a field that contains XML and expands it into an actual datastructure."
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors         = ["Clever Age", "William Pottier"]
  s.email           = 'wpottier@clever-age.com'
  s.homepage        = "http://www.clever-age.com/"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','Gemfile','LICENSE']

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 1.4.0", "< 2.0.0"
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'xml-simple'

  s.add_development_dependency 'logstash-devutils'
end

