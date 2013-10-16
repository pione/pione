require 'pione/test-helper'

TestHelper.scope do |this|
  this::FILENAMES = [
    [ "Test(keita.yamaguchi@gmail.com)+test@13790a8dadb31a8654edd39e17e753e9.ppg",
      { package_name: "Test",
        edition: "keita.yamaguchi@gmail.com",
        tag: "test",
        digest: "13790a8dadb31a8654edd39e17e753e9" }
    ],
    [ "Test(keita.yamaguchi@gmail.com)+test@13790a8dadb31a8654edd39e17e753e9",
      { package_name: "Test",
        edition: "keita.yamaguchi@gmail.com",
        tag: "test",
        digest: "13790a8dadb31a8654edd39e17e753e9" }
    ],
    [ "Test+test@13790a8dadb31a8654edd39e17e753e9.ppg",
      { package_name: "Test",
        edition: "origin",
        tag: "test",
        digest: "13790a8dadb31a8654edd39e17e753e9" }
    ],
    [ "Test+test.ppg",
      { package_name: "Test",
        edition: "origin",
        tag: "test",
        digest: nil }
    ],
    [ "Test@13790a8dadb31a8654edd39e17e753e9.ppg",
      { package_name: "Test",
        edition: "origin",
        tag: nil,
        digest: "13790a8dadb31a8654edd39e17e753e9" }
    ]
  ]

  describe Pione::Package::PackageFilename do
    it "should parse filename" do
      this::FILENAMES.each do |(filename, data)|
        Package::PackageFilename.parse(filename).tap do |fname|
          fname.package_name.should == data[:package_name]
          fname.edition.should == data[:edition]
          fname.tag.should == data[:tag]
          fname.digest.should == data[:digest]
        end
      end
    end

    it "should build package filename string" do
      this::FILENAMES.each do |(filename, _)|
        Package::PackageFilename.parse(filename).string(true).should == File.basename(filename, ".ppg") + ".ppg"
        Package::PackageFilename.parse(filename).string(false).should == File.basename(filename, ".ppg")
      end
    end
  end
end
