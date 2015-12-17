FROM ruby:2.2.3-onbuild

COPY config/mongoid-docker.yml config/mongoid.yml
EXPOSE 3000
CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]
