# frozen_string_literal: true

require "pastel"

module Cli
  module Colors
    module_function

    def heading(text, io: $stdout)
      pastel(io).bold(text)
    end

    def ok(text = "OK", io: $stdout)
      pastel(io).green(text)
    end

    def warn(text = "WARN", io: $stdout)
      pastel(io).yellow(text)
    end

    def fail(text = "FAIL", io: $stdout)
      pastel(io).red(text)
    end

    def pastel(io)
      Pastel.new(enabled: io.tty?)
    end
  end
end
