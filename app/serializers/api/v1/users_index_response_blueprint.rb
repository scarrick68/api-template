module Api
  module V1
    class UsersIndexResponseBlueprint < BaseBlueprint
      field :data do |payload|
        UserBlueprint.render_as_hash(payload[:records])
      end

      field :meta
    end
  end
end
