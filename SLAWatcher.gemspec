# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "SLAWatcher"
  s.version     = "0.0.1"
  s.authors     = ["Adrian Toman"]
  s.email       = ["adrian.toman@gmail.com"]
  s.homepage    = ""
  s.summary     = "Tool for watching internal SLA"
  s.description = ""

  s.rubyforge_project = "SLAWatcher"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:

  s.add_dependency "splunk-client"
  s.add_dependency "parse-cron"
  s.add_dependency "gli","= 1.6.0"
  s.add_dependency "activerecord","~> 3.2.12"
end
