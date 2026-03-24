class MetalsValueGetterJob < ApplicationJob
  queue_as :default

  def perform
    GetRealTimeMetalsValueCommand.call
  end
end