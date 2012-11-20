require_relative '../test-util'

describe 'Pione::URIScheme::LocalScheme' do
  it 'should be suported by PIONE' do
    URI.parse("local:/").should.be.pione
  end

  it 'should be storage' do
    URI.parse("local:/").should.be.storage
  end

  it 'should be local scheme URI' do
    URI.parse("local:./output").should.kind_of Pione::URIScheme::LocalScheme
  end

  it 'should get scheme name' do
    URI.parse("local:./output").scheme.should == 'local'
  end

  it 'should get the path of "local:./output"' do
    URI.parse("local:./output").path.should == './output'
  end

  it 'should get the path of "local:~/output"' do
    URI.parse("local:~/output").path.should == '~/output'
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

  it 'should convert as a directory' do
    URI.parse("local:/home/keita").as_directory.should.be.directory
  end

  it 'should get absolute path of "local:./output"' do
    URI.parse("local:./output").absolute.path.should == File.join(Dir.pwd, "output")
  end

  it 'should get absolute path of "local:~/output"' do
    path = File.join(Pathname.new("~").expand_path, "output")
    URI.parse("local:~/output").absolute.path.should == path
  end

  it 'should get absolute path of "local:./output/"' do
    URI.parse("local:./output/").absolute.path.should == File.join(Dir.pwd, "output") + "/"
  end
end

