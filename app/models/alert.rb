class Alert < ApplicationRecord
  belongs_to :flow
  belongs_to :measurement_point
end
