require 'clockwork'

module Clockwork
  handler do |job|
    `pione clean`
  end

  every(1.day, "clean", :at => ['00:00', '12:00'])
end
