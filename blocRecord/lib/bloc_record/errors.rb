require 'sqlite3'
require_relative 'selection'

module Errors
  def method_missing(m, *args, &block)
    method = m.to_s
    if method.include? "find_by"
      find_by(*args,value)
    else
      super
    end
  end
end
