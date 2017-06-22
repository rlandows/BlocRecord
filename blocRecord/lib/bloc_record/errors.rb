require 'sqlite3'
require_relative 'selection'
require_relative 'persistence'

module Errors
  def method_missing(m, *args, &block)
    method = m.to_s
    arr = method.split("_")
    if method.start_with?("find_by")
      find_by(arr[-1],*args)
    else
     super
    end
  end
end
