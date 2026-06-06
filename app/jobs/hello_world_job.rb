class HelloWorldJob < ApplicationJob
  queue_as :default

  def perform(name = "World")
    "Hello, #{name}!"
  end
end
