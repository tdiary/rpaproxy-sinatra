require 'rake'

unless ENV['RACK_ENV'] == 'production'
  task default: :spec

  require 'rspec/core'
  require 'rspec/core/rake_task'

  desc "Run all specs in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "spec/**/*_spec.rb"
  end
end
