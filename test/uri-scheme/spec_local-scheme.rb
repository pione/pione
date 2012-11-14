require_relative '../test-util'

describe 'Pione::URIScheme::LocalScheme' do
  it 'should be local scheme URI' do
    URI.parse("local:./output").should.kind_of Pione::URIScheme::LocalScheme
  end

  it 'should get scheme name' do
    URI.parse("local:./output").scheme.should == 'local'
  end

  it 'should get the path of "local:./output"' do
    URI.parse("local:./output").path.should == './output'
  end

  it 'should get the path of "local:./a/b/c"' do
    URI.parse("local:./a/b/c").path.should == './a/b/c'
  end

  it 'should get the path of "local:/output"' do
    URI.parse("local:/output").path.should == '/output'
  end

  it 'should get the path of "local:/"' do
    URI.parse("local:/").path.should == '/'
  end

  it 'should get the path of "local:/a/b/c"' do
    URI.parse("local:/a/b/c").path.should == '/a/b/c'
  end

  it 'should be a directory' do
    URI.parse("local:/home/keita/").should.be.directory
  end

  it 'should be a file' do
    URI.parse("local:/home/keita/test.rb").should.be.file
  end

  it 'should get absolute path' do
    URI.parse("local:./output").absolute.path.should == File.join(Dir.pwd, "output")
  end
end

