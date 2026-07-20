require "test_helper"
require "stringio"

class CliColorsTest < ActiveSupport::TestCase
  class FakeIo
    def initialize(tty:)
      @tty = tty
    end

    def tty?
      @tty
    end
  end

  test "ok uses green formatting" do
    io = FakeIo.new(tty: true)

    colored = Cli::Colors.ok("OK", io: io)

    assert_equal "\e[32mOK\e[0m", colored
  end

  test "warn uses yellow formatting" do
    io = FakeIo.new(tty: true)

    colored = Cli::Colors.warn("WARN", io: io)

    assert_equal "\e[33mWARN\e[0m", colored
  end

  test "fail uses red formatting" do
    io = FakeIo.new(tty: true)

    colored = Cli::Colors.fail("FAIL", io: io)

    assert_equal "\e[31mFAIL\e[0m", colored
  end

  test "heading uses bold formatting" do
    io = FakeIo.new(tty: true)

    formatted = Cli::Colors.heading("Title", io: io)

    assert_equal "\e[1mTitle\e[0m", formatted
  end

  test "tty false disables color output" do
    io = FakeIo.new(tty: false)

    assert_equal "OK", Cli::Colors.ok("OK", io: io)
    assert_equal "WARN", Cli::Colors.warn("WARN", io: io)
    assert_equal "FAIL", Cli::Colors.fail("FAIL", io: io)
    assert_equal "Title", Cli::Colors.heading("Title", io: io)
  end
end
