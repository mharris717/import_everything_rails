$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'import_everything_rails'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end
