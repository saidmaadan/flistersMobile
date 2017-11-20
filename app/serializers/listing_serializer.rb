class ListingSerializer < ActiveModel::Serializer
  attributes :id, :listing_name, :address,
             :apartment_type, :bedroom, :bathroom, :summary,
             :price, :active, :image, :unavailable_dates

  def unavailable_dates
    @instance_options[:unavailable_dates]
  end

  def image
    @instance_options[:image]
  end

  class UserSerializer < ActiveModel::Serializer
    attributes :email, :full_name, :image
  end

  belongs_to :user, serializer: UserSerializer, key: :host
end
