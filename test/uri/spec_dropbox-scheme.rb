require_relative '../test-util'

describe 'Pione::URI::Dropbox' do
  it 'get component informations' do
    uri = ::URI.parse("dropbox:/Pione")
    uri.should.kind_of Pione::URI::Dropbox
    uri.scheme.should == 'dropbox'
    uri.path.should == '/Pione'
    ::URI.parse("dropbox:/").path.should == "/"
    ::URI.parse("dropbox:/a/b/c").path.should == "/a/b/c"
  end
end
