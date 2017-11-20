class Api::V1::ListingsController < ApplicationController

  def index
    if !params[:address].blank?
      listings = Listing.where(active: true).near(params[:address], 5, order: 'distance')
    else
      listings = Listing.where(active: true)
    end

    if !params[:start_date].blank? && !params[:end_date].blank?
      start_date = DateTime.parse(params[:start_date])
      end_date = DateTime.parse(params[:end_date])

      listings = listings.select { |listing|
          # Check #1: Check if there are any approved reservations overlap this date range
          reservations = Reservation.where(
            "listing_id = ? AND (start_date <= ? AND end_date >= ?) AND status = ?",
            listing.id, end_date, start_date, 1
          ).count

          # Check #2: Check if there are any unavailable dates within that date range
          calendars = Calendar.where(
            "listingd_id = ? AND status = ? and day BETWEEN ? AND ?",
            listing.id, 1, start_date, end_date
          ).count

          reservations == 0 && calendars == 0
      }
    end

    render json: {
      listings: listings.map { |listing| listing.attributes.merge(image: listing.backgroud_image('medium'), instant: listing.instant != "Request") },
      is_success: true
    }, status: :ok

  end

  def show
    listing = Listing.find(params[:id])

    today = Date.today
    reservations = Reservation.where(
      "listing_id = ? AND (start_date >= ? AND end_date >= ?) AND status = ?",
      params[:id], today, today, 1
    )

    unavailable_dates = reservations.map { |r|
      (r[:start_date].to_datetime...r[:end_date].to_datetime).map { |day| day.strftime("%Y-%m-%d") }
    }.flatten.to_set

    calendars = Calendar.where(
      "listing_id = ? and status = ? and day >= ?",
      params[:id], 1, today
    ).pluck(:day).map(&:to_datetime).map { |day| day.strftime("%Y-%m-%d") }.flatten.to_set

    unavailable_dates.merge calendars

    if !listing.nil?
      listing_serializer = ListingSerializer.new(
        listing,
        image: listing.backgroud_image('medium'),
        unavailable_dates: unavailable_dates
      )
      render json: { listing: listing_serializer, is_success: true}, status: :ok
    else
      render json: { error: "Invalid ID", is_success: false}, status: 422
    end

  end

  def your_listings
    listings = current_user.listings
    render json: {
      listings: listings.map { |r| r.attributes.merge(image: r.backgroud_image('medium'), instant: r.instant != "Request") },
      is_success: true
    }, status: :ok

  end
end
