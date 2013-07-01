require_relative '../test-util'

$stdout = STDOUT
$stderr = STDERR

describe "Pione::Location::GitRepositoryLocation" do
  before do
    Global.git_repository_directory
  end

  #
  # test git URL handling
  #

  it "should get repository location of local filesystem" do
    location = Location[git: "/path/to/repos.git"]
    location.location_type.should == :git_repository
    location.address.should == "/path/to/repos.git"
  end

  it "should get repository locatoion of git server" do
    location = Location[git: "git://path/to/repos.git"]
    location.location_type.should == :git_repository
    location.address.should == "git://path/to/repos.git"
  end

  it "should get repository location of http" do
    location = Location[git: "https://github.com/pione/pione.git"]
    location.location_type.should == :git_repository
    location.address.should == "https://github.com/pione/pione.git"
  end

  it "should get repository location of ssh" do
    location = Location[git: "git@github.com:pione/pione.git"]
    location.location_type.should == :git_repository
    location.address.should == "git@github.com:pione/pione.git"
  end

  #
  # test repository operations
  #

  shared "git repository location" do
    it "should get hash id from tag" do
      @location.ref(tag: "v0.1.0").should == "2bb5f582387ac04b429db26dc1c597cf0b8fc0fe"
      @location.should.has_local
    end

    it "should get hash id from branch" do
      @location.ref(branch: "master").should == "d0a3837fe04d11ac012db1994c4774a3e39c00fc"
      @location.should.has_local
    end

    it "should get compact hash id" do
      @location.compact_hash_id.should == "d0a3837"
    end

    it "should export repository at HEAD" do
      exported = Location[Temppath.mkdir]
      @location.export(exported)
      (exported + "package.yml").should.exist
      (exported + "scenario" + "scenario.yml").should.exist
    end

    it "should export repository at the hash id" do
      exported = Location[Temppath.mkdir]
      (@location + {hashid: "2bb5f58"}).export(exported)
      (exported + "package.yml").should.exist
      (exported + "scenario" + "scenario.yml").should.exist
    end

    it "should export repository at the tag v0.1.0" do
      exported = Location[Temppath.mkdir]
      (@location + {tag: "v0.1.0"}).export(exported)
      (exported + "package.yml").should.exist
      (exported + "scenario" + "scenario.yml").should.exist
    end

    it "should export repository at the branch master" do
      exported = Location[Temppath.mkdir]
      (@location + {branch: "master"}).export(exported)
      (exported + "package.yml").should.exist
      (exported + "scenario" + "scenario.yml").should.exist
    end
  end

  describe "local" do
    before do
      @repos_location = Location[Temppath.mkdir]
      repos_zip = TestUtil::TEST_PACKAGE_DIR + "HelloWorld-gitrepos.zip"
      Util::Zip.uncompress(repos_zip, @repos_location)
    end

    describe "head" do
      before do
        @location = Location[git: @repos_location.path]
      end

      behaves_like "git repository location"
    end

    describe "with tag" do
      before do
        @location = Location[git: @repos_location.path, tag: "v0.1.0"]
      end

      behaves_like "git repository location"
    end

    describe "with hash id" do
      before do
        @location = Location[git: @repos_location.path, hash_id: "a5dd7b0"]
      end

      behaves_like "git repository location"
    end

    describe "with branch" do
      before do
        @location = Location[git: @repos_location.path, branch: "master"]
      end

      behaves_like "git repository location"
    end
  end

  # describe "http" do
  #    before do
  #     @repos_location = Location[Temppath.mkdir]
  #     repos_zip = TestUtil::TEST_PACKAGE_DIR + "HelloWorld-gitrepos.zip"
  #     Util::Zip.uncompress(repos_zip, @repos_location)
  #     @server = TestUtil::WebServer.start(@repos_location)
  #     @location = Location[git: @server.root.uri]
  #   end

  #   after do
  #     @server.terminate
  #   end

  #   behaves_like "git repository location"
  # end
end

