class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :admin, as: :boolean
    field :allow_password_change, as: :boolean
    field :confirmation_sent_at, as: :date_time
    field :confirmation_token, as: :text
    field :confirmed_at, as: :date_time
    field :deleted_at, as: :date_time
    field :email, as: :text
    field :image, as: :text
    field :name, as: :text
    field :nickname, as: :text
    field :provider, as: :text
    field :uid, as: :text
    field :unconfirmed_email, as: :text
    field :field_test_memberships, as: :has_many
  end
end
