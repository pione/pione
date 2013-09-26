require 'pione/test-helper'

describe 'Pione::Location::MyFTPScheme' do
  it 'should be supported by PIONE' do
    URI.parse("myftp:/").should.be.pione
  end

  it 'should be storage' do
    URI.parse("myftp:/").should.be.storage
  end

  it 'should be myftp scheme URI' do
    URI.parse("myftp:./output").should.kind_of Pione::Location::MyFTPScheme
  end

  it 'should be a directory' do
    URI.parse("myftp:/home/keita/").should.be.directory
  end

  it 'should be a file' do
    URI.parse("myftp:/home/keita/test.rb").should.be.file
  end

  it 'should convert as a directory' do
    URI.parse("myftp:/home/keita").as_directory.should.be.directory
  end

  it 'should normalize "myftp:./output"' do
    uri = URI.parse("myftp:./output").normalize
    uri.user.should.not.nil
    uri.password.should.not.nil
    uri.host.should == Util::IPAddress.myself
    uri.port.should == Location::MyFTPScheme::PORT
    uri.path.should == File.join(Dir.pwd, "output")
  end

  it 'should normalize "myftp:./output/"' do
    URI.parse("myftp:./output/").normalize.path.should == File.join(Dir.pwd, "output") + "/"
  end

  it 'should normalize "myftp:~/output"' do
    uri = URI.parse("myftp:~/output").normalize
    uri.user.should.not.nil
    uri.password.should.not.nil
    uri.host.should == Util::IPAddress.myself
    uri.port.should == Location::MyFTPScheme::PORT
    uri.path.should == File.join(Pathname.new("~").expand_path, "output")
  end

  it 'should normalize "myftp://abc:123@myself/output/"' do
    uri = URI.parse("myftp://abc:123@myself/output/").normalize
    uri.user.should == "abc"
    uri.password.should == "123"
    uri.host.should == Util::IPAddress.myself
    uri.port.should == Location::MyFTPScheme::PORT
    uri.path.should == "/output/"
  end

  it 'should get ftp scheme URI' do
    uri = URI.parse("myftp://abc:123@myself/output/").to_ftp_scheme
    uri.scheme == "ftp"
    uri.user == "abc"
    uri.password.should == "123"
    uri.host.should == Util::IPAddress.myself
    uri.port.should == Location::MyFTPScheme::PORT
    uri.path.should == "/"
  end

  TestHelper::Location.test_scheme(__FILE__)
end

