FROM ruby:3.3.0-alpine3.18

# Install dependencies
RUN apk add --update --no-cache \
    build-base \
    postgresql-dev \
    postgresql-client \
    tzdata \
    nodejs \
    yarn \
    git \
    bash \
    less \
    libpq \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set force_ruby_platform true
RUN bundle install --jobs 4 --retry 3

# Copy package.json if it exists, then install JavaScript dependencies if package.json exists
COPY package.json* ./
RUN if [ -f "package.json" ]; then \
      yarn install --check-files; \
    fi

# Copy application code
COPY . .

# Add a script to be executed every time the container starts
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Start the main process
CMD ["rails", "server", "-b", "0.0.0.0"]
