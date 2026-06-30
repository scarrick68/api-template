require "test_helper"

class AdminToolsDashboardTest < ApplicationDispatchTest
  test "dashboard renders expected admin tool links" do
    sign_in create(:admin), scope: :admin

    get "/admin/tools"

    assert_response :success
    assert_select "h1", "Admin Dashboard"
    assert_select "a[href='/admin/tools']", text: "Admin Dashboard"

    assert_select "a[href='/avo']", text: "Avo"
    assert_select "a[href='/pghero']", text: "PgHero"
    assert_select "a[href='/blazer']", text: "Blazer"
    assert_select "a[href='/good_job']", text: "GoodJob"
    assert_select "a[href='/solid_errors']", text: "Solid Errors"
    assert_select "a[href='/field_test']", text: "Field Test"
    assert_select "a[href='/flipper']", text: "Flipper"
    assert_select "a[href='/searchjoy']", text: "Searchjoy"
  end
end
