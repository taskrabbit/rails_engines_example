$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "admin"
  s.version     = "0.0.1"
  s.authors     = ["Brian Leonard"]
  s.email       = ["brian@bleonard.com"]
  s.homepage    = "https://github.com/taskrabbit/rails_engines_example"
  s.summary     = "Admin user tools"
  s.description = "Adminstrate!"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails",       "~> 4.0.1"
  s.add_dependency "redcarpet"
  s.add_dependency "kaminari"
  s.add_dependency "kaminari-bootstrap"

  # admin can use other engines' models
  s.add_dependency "content"
  s.add_dependency "account"
end
