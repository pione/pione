require_relative '../test-util'

describe 'URI patch' do
  it 'should be a directory' do
    URI.parse("http://locahost/a/b/c/").should.be.directory
  end

  it 'should be not a directory' do
    URI.parse("http://locahost/a/b/c").should.be.not.directory
  end

  it 'should be a file' do
    URI.parse("http://locahost/a/b/c").should.be.file
  end

  it 'should be not a file' do
    URI.parse("http://locahost/a/b/c/").should.be.not.file
  end

  it 'should convert as a directory' do
    URI.parse("http://locahost/a/b/c").as_directory.should.be.directory
  end
end
