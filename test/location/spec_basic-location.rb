require_relative '../test-util'

class TestLocation < Location::BasicLocation
  set_scheme "test"
end

describe 'Location::BasicLocation' do
  it 'should get by Location[]' do
    Location["test:/a"].should.kind_of TestLocation
  end

  it 'should raise an exception when the URI is unknown' do
    should.raise(ArgumentError) {Location["testa:/a"]}
  end

  it 'should be equal' do
    Location["test:/a"].should == Location["test:/a"]
  end

  it 'should be not equal' do
    Location["test:/a"].should != Location["test:/a/"]
  end

  it 'should be as directory' do
    Location["test:/a"].as_directory.path.should == Pathname.new("/a/")
  end

  it 'should be append' do
    (Location["test:/a/b"] + "c").path.should == Pathname.new("/a/b/c")
  end

  it 'should get basename' do
    Location["test:/a/name"].basename.should == "name"
  end
end
