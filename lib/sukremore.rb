require "sukremore/version"
require "sukremore/client"

module Sukremore
  def logger
    if defined? Rails
      Rails.logger
    else
      Logger.new(STDOUT)
    end
  end
end
