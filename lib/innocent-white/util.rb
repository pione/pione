require 'uuidtools'

module InnocentWhite
  module Util
    def self.uuid
      UUIDTools::UUID.random_create.to_s
    end
  end
end
