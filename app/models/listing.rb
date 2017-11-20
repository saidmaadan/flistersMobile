class Listing < ApplicationRecord
  enum instant: {Request: 0, Instant: 1}

  belongs_to :user
  has_many :photos
  has_many :reservations
  has_many :guest_reviews
  has_many :calendars

  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  extend FriendlyId
  friendly_id :slug_listings, use: :slugged

   def slug_listings
     [
       :listing_name,
       [:listing_name, :listing_type],
       [:listing_name, :listing_type, :apartment_type,],
       [:listing_name, :listing_type, :apartment_type, :address],
       [:listing_name, :listing_type, :apartment_type, :address]
     ]
   end

    validates :listing_type, presence: true
    validates :apartment_type, presence: true
    validates :accommodate, presence: true
    validates :bedroom, presence: true
    validates :bathroom, presence: true
    #validates :listing_name, presence: true

    def backgroud_image(size)
      if self.photos.length > 0
        self.photos[0].image.url(size)
      else
        "listings-blank.jpg"
      end
    end

    def average_rating
      guest_reviews.count == 0 ? 0 : guest_reviews.average(:star).round(2).to_i
    end

end
