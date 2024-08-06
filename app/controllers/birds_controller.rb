class BirdsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response

  def index
    birds = Bird.all
    render json: birds
  end

  def create
    bird = Bird.create!(bird_params)
    render json: bird, status: :created
  end

  def show
    bird = find_bird
    render json: bird
  end

  def update
    bird = find_bird
    bird.update!(bird_params)
    render json: bird
  end

  def destroy
    bird = find_bird
    bird.destroy
    head :no_content
  end

  private

  def find_bird
    Bird.find(params[:id])
  end

  def bird_params
    params.permit(:name, :species, :likes)
  end

  def render_not_found_response
    render json: { error: "Bird not found" }, status: :not_found
  end

  def render_unprocessable_entity_response(invalid)
    render json: { errors: invalid.record.errors.full_messages }, status: :unprocessable_entity
  end
end
