module Api
  module V1
    class UsersShowResponseBlueprint < BaseBlueprint
      field :data do |payload|
        UserBlueprint.render_as_hash(payload[:data])
      end
    end
  end
end
