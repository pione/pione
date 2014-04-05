# This file should be loaded in spec files only.

require 'bacon'
require 'erb'
require 'pione'
require 'rootage/test-helper'

Pione::Command.load_all

Pione::Global.git_package_directory = Pione::Location[Temppath.mkdir]

Pione::Global.define_internal_item(:project_root) do |item|
  item.init = Pione::Location[File.dirname(__FILE__)] + ".." + ".."
end

Pione::Global.define_internal_item(:test_start_time) do |item|
  item.init = Time.now
end

Pione::Global.define_internal_item(:test_report) do |item|
  item.define_updater do
    filename = Pione::Global.test_start_time.strftime("test-report.txt")
    Pione::Global.project_root + filename
  end
end

module Pione
  module TestHelper
    DIR = Location[File.dirname(__FILE__)]
    TEST_DATA_DIR = DIR + "test-data"
    TEST_PACKAGE_DIR = TEST_DATA_DIR + "package"

    def self.scope(&b)
      @scope_id = (@scope_id || 0) + 1
      mod = Module.new
      const_set("MODULE%s" % @scope_id, mod)
      mod.send(:define_method, :this) do
        mod
      end
      mod.module_eval(&b)
    end

    def self.scope_of(mod)
      eval(mod.name.split("::").reverse.drop(1).reverse.join("::"))
    end
  end
end

# load test helpers
require "pione/test-helper/extension"             # extensions for test
require "pione/test-helper/webserver"             # fake HTTP server
require "pione/test-helper/location-helper"       # location test helper
require "pione/test-helper/command-helper"        # command test helper
require "pione/test-helper/parser-helper"         # parser test utility
require "pione/test-helper/transformer-helper"    # transformer test utility
require "pione/test-helper/lang-helper"           # language test method
require "pione/test-helper/package-helper"        # pakcage test
require "pione/test-helper/tuple-helper"          # tuple test
require "pione/test-helper/tuple-space-helper"    # tuple space
require "pione/test-helper/internet-connectivity" # check internet connection

# extend bacon's context
class Bacon::Context
  include Pione
  include Pione::TestHelper::TransformerInterface
  include Pione::TupleSpace::TupleSpaceInterface

  alias :orig_it :it
  def it(desc, &b)
    time = Time.now
    orig_it(desc, &b)
    line = "[%s] %s: %s\n" % [@name, desc, (Time.now - time).round(3)]
    Pione::Global.test_report.append(line)
  end
end

# init
include Pione
