module Svc
  class Base
    def self.call(...)
      new(...).call
    end
  end
end
