require File.dirname(__FILE__) + '/../lib/legislation_uk'

def fixture(filename)
  open("#{File.dirname(__FILE__)}/fixtures/#{filename}").read
end