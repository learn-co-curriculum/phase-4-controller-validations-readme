class Bird < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  def create
    bird = Bird.create(bird_params)
    if bird.valid?
      render json: bird, status: :created
    else
      render json: { errors: bird.errors }, status: :unprocessable_entity
    end
  end
end
