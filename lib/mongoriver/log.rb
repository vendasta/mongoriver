module Mongoriver
  module Logging
    def log
      @@logger ||= Log4r::Logger.new("Stripe::Mongoriver", Log4r::ALL)
    end
  end
end
