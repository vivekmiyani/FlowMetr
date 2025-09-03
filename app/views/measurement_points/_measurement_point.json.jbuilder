json.extract! measurement_point, :id, :name, :node_type, :webhook_token, :flow_id, :created_at, :updated_at
json.url measurement_point_url(measurement_point, format: :json)
