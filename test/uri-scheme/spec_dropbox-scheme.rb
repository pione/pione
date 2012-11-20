require_relative '../test-util'

describe 'Pione::URIScheme::DropboxScheme' do
  it 'should be suported by PIONE' do
    URI.parse("dropbox:/").should.be.pione
  end

  it 'should be storage' do
    URI.parse("dropbox:/").should.be.storage
  end

  it 'should be dropbox scheme URI' do
    URI.parse("dropbox:/Pione").should.kind_of Pione::URIScheme::DropboxScheme
  end

  it 'should get scheme name' do
    URI.parse("dropbox:/Pione").scheme.should == 'dropbox'
  end

  it 'should get the path of "dropbox:/Pione"' do
    URI.parse("dropbox:/Pione").path.should == '/Pione'
  end

  it 'should get the path of "dropbox:/"' do
    URI.parse("dropbox:/").path.should == "/"
  end

  it 'should get the path of "dropbox:/a/b/c"' do
    URI.parse("dropbox:/a/b/c").path.should == "/a/b/c"
  end
end
