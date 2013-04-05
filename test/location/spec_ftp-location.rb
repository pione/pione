require_relative '../test-util'

begin
  @uri = URI("ftp://anonymous:test@localhost/pione/test-a.txt")
  @ftp = Resource[@uri]
  @ftp.create("abc")
  @ftp.delete

  describe 'Location::FTPLocation' do
    before do
      path = Tempfile.new("spec_resource_").path
      # @uri = URI("ftp://anonymous:test@localhost/pione/test-a.txt")
      # @ftp = Resource[@uri]
    end

    it 'should create a file and read it' do
      @ftp.create("abc")
      @ftp.read.should == "abc"
      @ftp.delete
    end

    it 'should update a file' do
      @ftp.create("abc")
      @ftp.read.should == "abc"
      @ftp.update("defg")
      @ftp.read.should == "defg"
      @ftp.update("hi")
      @ftp.read.should == "hi"
      @ftp.delete
    end
  end
end
