$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs'

Spec::Runner.configure do |config|
  config.after(:each) { FakeFS::FileSystem.clear }
end

