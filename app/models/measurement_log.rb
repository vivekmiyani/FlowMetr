class MeasurementLog < ApplicationRecord
  belongs_to :run
  belongs_to :measurement_point
end
