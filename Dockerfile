FROM ruby:2.3.2-alpine

RUN apk add --no-cache --update alpine-sdk
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install && apk del alpine-sdk

COPY . /usr/src/app
COPY config/mongoid-docker.yml config/mongoid.yml
EXPOSE 3000
CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]
