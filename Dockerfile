# Use the official Ruby image from the Docker Hub
FROM ruby:3.0.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  postgresql-client \
  build-essential \
  libpq-dev  # Changed from libsqlite3-dev to libpq-dev

# Set an environment variable to skip installing Gem documentation
ENV BUNDLE_WITHOUT=development:test

# Set the working directory inside the container
WORKDIR /myapp

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock

# Install the gems specified in the Gemfile
RUN bundle install

# Copy the rest of the application code into the container
COPY . /myapp

# Precompile Rails assets
RUN bundle exec rake assets:precompile

# Expose the port the app runs on
EXPOSE 3000

# Set environment variables for PostgreSQL
ENV PGHOST=db
ENV PGUSER=myapp_user
ENV PGPASSWORD=myapp_password
ENV PGDATABASE=myapp_development

# Set the default command to run when starting the container
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && rails db:migrate && rails server -b 0.0.0.0"]

