class Api::V1::ReservationsController < ApplicationController
  before_action :authenticate_with_token!
  before_action :set_reservation, only: [:approve, :decline]

  def create
    listing = Listing.find(params[:listing_id])

    if current_user.stripe_id.blank?
      render json: { error: "Update your payment method", is_success: false}, status: 404
    elsif current_user == listing.user
      render json: { error: "You cannot book your own property", is_success: false}, status: 404
    else
      # Calculate the total amount of that reservation
      start_date = DateTime.parse(reservation_params[:start_date])
      end_date = DateTime.parse(reservation_params[:end_date])

      days = (end_date - start_date).to_i + 1
      special_days = Calendar.where(
        "listing_id = ? AND status = ? AND day BETWEEN ? AND ? AND price <> ?",
        listing.id, 0, start_date, end_date, listing.price
      ).pluck(:price)

      # Make a reservation
      reservation = current_user.reservations.build(reservation_params)
      reservation.listing = listing
      reservation.price = listing.price
      reservation.total = listing.price * (days - special_days.count)

      special_days.each do |d|
        reservation.total += d.price
      end

      if reservation.Waiting! && listing.Instant?
        charge(listing, reservation)
      end

      render json: { is_success: true}, status: :ok

    end

  end

  def reservations_by_listing
    reservations = Reservation.where(listing_id: params[:id])
    reservations = reservations.map { |r| ReservationSerializer.new(r, avatar_url: r.user.image) }
    render json: {reservations: reservations, is_success: true}, status: :ok
  end

  def approve
    if @reservation.listing.user_id == current_user.id
      charge(@reservation.listing, @reservation)
      render json: {is_success: true}, status: :ok
    else
      render json: {error: "No Permission", is_success: false}, status: 404
    end
  end

  def decline
    if @reservation.listing.user_id == current_user.id
      @reservation.Declined!
      render json: {is_success: true}, status: :ok
    else
      render json: {error: "No Permission", is_success: false}, status: 404
    end
  end

  private
    def set_reservation
      @reservation = Reservation.find(params[:id])
    end

    def reservation_params
      params.require(:reservation).permit(:start_date, :end_date)
    end

    def charge(listing, reservation)
      if !reservation.user.stripe_id.blank? && !listing.user.merchant_id.blank?
        customer = Stripe::Customer.retrieve(reservation.user.stripe_id)
        charge = Stripe::Charge.create(
          :customer => customer.id,
          :amount => reservation.total * 100,
          :description => listing.listing_name,
          :currency => 'usd',
          :destination => {
            :amount => reservation.total * 90,
            :account => listing.user.merchant_id
          }
        )

        if charge
          reservation.Approved!
        else
          reservation.Declined!
        end
      end
    rescue Stripe::CardError => e
      reservation.Declined!
      render json: {error: e.message, is_success: false}, status: 404
    end
end
