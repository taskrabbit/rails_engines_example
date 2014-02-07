begin
  require 'byebug'

  module Kernel
    alias :debugger :byebug
  end

rescue LoadError => e
  # byebug isn't installed - no debugging here!
end
