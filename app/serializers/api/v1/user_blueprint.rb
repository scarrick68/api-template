module Api
  module V1
    class UserBlueprint < Blueprinter::Base
      identifier :id

      fields :email,
             :name,
             :age,
             :height_ft,
             :height_inches,
             :weight_lbs,
             :activity_level,
             :goal,
             :time_zone,
             :admin,
             :created_at,
             :updated_at
    end
  end
end
