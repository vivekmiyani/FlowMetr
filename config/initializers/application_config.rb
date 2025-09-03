# config/initializers/application_config.rb
Rails.application.configure do
  config.x.app_url = case Rails.env
                      when 'production'
                        'https://flowmetr.com'
                      when 'staging'
                        'https://flowmetr-staging.onrender.com'
                      else # development, test, etc.
                        'http://localhost:3000'
                      end
end