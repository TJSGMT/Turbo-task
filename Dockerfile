#---------------------------Stage-1 Image Builder-------------------------
    FROM ruby:3.0.2-slim AS backend-builder

    # Install only necessary packages and PostgreSQL client libraries
    RUN apt-get update -qq && apt-get install -y \
      build-essential \
      libpq-dev \
      nodejs \
      yarn \
      postgresql-client \
      && rm -rf /var/lib/apt/lists/*
    
    # Set an environment variable to skip installing Gem documentation
    ENV BUNDLE_WITHOUT=development:test
    
    # Set the working directory inside the container
    WORKDIR /myapp
    
    # Copy the Gemfile and Gemfile.lock into the container
    COPY Gemfile Gemfile.lock ./
    
    # Install the gems specified in the Gemfile
    RUN bundle install --jobs=4 --retry=3
    
    # Copy the rest of the application code into the container
    COPY . .
    
    # Precompile assets
    RUN RAILS_ENV=production SECRET_KEY_BASE=your_generated_secret_key_base bundle exec rake assets:precompile
    
    #--------------------------Stage-2 Final Image---------------------------
    FROM ruby:3.0.2-slim
    
    # Install minimal dependencies for running the app
    RUN apt-get update -qq && apt-get install -y \
      postgresql-client \
      && rm -rf /var/lib/apt/lists/*
    
    # Set the working directory inside the container
    WORKDIR /app
    
    # Copy the necessary files from the builder image
    COPY --from=backend-builder /usr/local/bundle /usr/local/bundle
    COPY --from=backend-builder /myapp /app
    
    # Expose the port the app runs on
    EXPOSE 3000
    
    # Set environment variables for PostgreSQL and Rails
    ENV PGHOST=db \
        PGUSER=myapp_user \
        PGPASSWORD=myapp_password \
        PGDATABASE=myapp_production \
        SECRET_KEY_BASE=your_generated_secret_key_base
    
    # Ensure the server.pid is removed and run database migrations before starting the server
    CMD ["bash", "-c", "rm -f tmp/pids/server.pid && rails db:migrate && rails server -b 0.0.0.0"]
    