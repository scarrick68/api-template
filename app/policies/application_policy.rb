class ApplicationPolicy
  class NotAuthorized < StandardError; end

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def show? = false
  def index? = false
  def create? = false
  def update? = false
  def destroy? = false
end
