require 'pione/test-util'
require 'pione/uri'

describe 'URI' do
  describe 'Local' do
    it 'should represent directory' do
      uri = ::URI.parse("local:/home/keita/")
      uri.should.kind_of Pione::URI::Local
      uri.scheme.should == 'local'
      uri.path.should == '/home/keita/'
      uri.should.be.absolute
      uri.should.be.directory
      (uri + "test.rb").should == ::URI.parse("local:/home/keita/test.rb")
    end

    it 'should represent file' do
      uri = ::URI.parse('local:/home/keita/test.rb')
      uri.should.kind_of Pione::URI::Local
      uri.scheme.should == 'local'
      uri.path.should == '/home/keita/test.rb'
      uri.should.be.absolute
      uri.should.be.file
    end
  end
end

