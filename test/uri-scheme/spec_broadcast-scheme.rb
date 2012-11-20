require_relative '../test-util'

describe 'Pione::URIScheme::BroadcastScheme' do
  it 'should be suported by PIONE' do
    URI.parse("broadcast://255.255.255.255").should.be.pione
  end

  it 'should be storage' do
    URI.parse("broadcast://255.255.255.255").should.be.not.storage
  end

  it 'should be broadcast scheme URI' do
    URI.parse("broadcast://255.255.255.255").should.kind_of Pione::URIScheme::BroadcastScheme
  end

  it 'should get scheme name' do
    URI.parse("broadcast://255.255.255.255").scheme.should == 'broadcast'
  end

  it 'should get the address and port of "broadcast://255.255.255.255"' do
    URI.parse("broadcast://255.255.255.255").tap do |uri|
      uri.host.should == '255.255.255.255'
      uri.port.should == nil
    end
  end

  it 'should get the address and port of "broadcast://255.255.255.255:12345"' do
    URI.parse("broadcast://255.255.255.255:12345").tap do |uri|
      uri.host.should == '255.255.255.255'
      uri.port.should == 12345
    end
  end

  it 'should get the address and port of "broadcast://"' do
    URI.parse("broadcast://").tap do |uri|
      uri.host.should == nil
      uri.port.should == nil
    end
  end
end
