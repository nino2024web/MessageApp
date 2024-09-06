class Friend < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  scope :recent_interactions, -> { order(last_interaction_at: :desc) }
end
