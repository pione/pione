require 'tempfile'
require 'innocent-white/test-util'
require 'innocent-white/uri'
require 'innocent-white/resource'

#include InnocentWhite

describe 'Resource' do
  describe 'Local' do
    before do
      path = Tempfile.new("spec_resource_").path
      @uri = ::URI.parse("local:#{path}")
      @local = Resource[@uri]
    end

    it 'should create a file' do
      @local.create("abc")
      File.read(@uri.path).should == "abc"
    end

    it 'should read a file' do
      @local.create("abc")
      @local.read.should == "abc"
      @local.read.should == "abc"
      @local.read.should.not == "def"
      File.delete(@uri.path)
      should.raise(Resource::NotFound) { @local.read }
    end

    it 'should update a file' do
      @local.create("abc")
      @local.read.should == "abc"
      @local.update("defg")
      @local.read.should == "defg"
      @local.update("hi")
      @local.read.should == "hi"
    end

    it 'should delete a file' do
      should.not.raise { @local.delete }
      @local.create("abc")
      @local.delete
    end
  end
end
