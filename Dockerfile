FROM ruby:2.3.0-onbuild

COPY config/mongoid-docker.yml config/mongoid.yml
EXPOSE 3000
CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]
