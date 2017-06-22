require 'bloc_record/base'

class Address < BlocRecord::Base

  def to_s
    "Address: #{address}"
  end
end
