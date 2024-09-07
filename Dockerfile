#---------------------------Stage-1 image builder-------------------------
  FROM ruby:3.0.2 AS backend-builder

  # Install dependencies
  RUN apt-get update -qq && apt-get install -y \
      nodejs \
      yarn \
      postgresql-client \
      build-essential \
      libpq-dev  # Changed to libpq-dev for PostgreSQL support
    
  # Set an environment variable to skip installing Gem documentation
  ENV BUNDLE_WITHOUT="development test"
  
  # Set the working directory inside the container
  WORKDIR /myapp
  
  # Copy the Gemfile and Gemfile.lock into the container
  COPY Gemfile /myapp/Gemfile
  COPY Gemfile.lock /myapp/Gemfile.lock
  
  # Install the gems specified in the Gemfile
  RUN bundle install
  
  # Copy the rest of the application code into the container
  COPY . /myapp
  
  # Precompile Rails assets in production mode (done in the builder stage)
  RUN RAILS_ENV=production bundle exec rake assets:precompile
  
  #--------------------------Stage-2 Final image---------------------------
  FROM ruby:3.0.2-slim
  
  # Set the working directory inside the container
  WORKDIR /app
  
  # Copy the bundled gems and precompiled assets from the builder stage
  COPY --from=backend-builder /usr/local/bundle /usr/local/bundle
  COPY --from=backend-builder /myapp /app
  
  # Expose the port the app runs on
  EXPOSE 3000
  
  # Set environment variables for PostgreSQL (consider using secrets or env files in production)
  ENV PGHOST=db
  ENV PGUSER=myapp_user
  ENV PGPASSWORD=myapp_password
  ENV PGDATABASE=myapp_production
  
  # Set the default command to run when starting the container
  CMD ["bash", "-c", "rm -f tmp/pids/server.pid && rails db:migrate && rails server -b 0.0.0.0"]  