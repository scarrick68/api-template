require "test_helper"
require "stringio"

class LocalCiProdLocalSmokeTest < ActiveSupport::TestCase
  test "run prints ok line on successful readiness" do
    LocalCi::ProdLocalSmokeTest.stubs(:wait_for_up!).returns(true)
    LocalCi::ProdLocalSmokeTest.stubs(:terminate_process).returns(nil)
    Process.stubs(:spawn).returns(12_345)

    out, _err = capture_io do
      LocalCi::ProdLocalSmokeTest.run!
    end

    assert_includes out, "prod-local smoke check passed"
  end

  test "run exits with error when readiness check fails" do
    LocalCi::ProdLocalSmokeTest.stubs(:wait_for_up!).raises(StandardError, "boom")
    LocalCi::ProdLocalSmokeTest.stubs(:terminate_process).returns(nil)
    Process.stubs(:spawn).returns(12_345)

    _out, err = capture_io do
      exit_error = assert_raises(SystemExit) { LocalCi::ProdLocalSmokeTest.run! }
      assert_equal 1, exit_error.status
    end

    assert_includes err, "ERROR"
    assert_includes err, "boom"
  end
end
