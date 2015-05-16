# Product Advertising API用リバースプロキシ

[![Build Status](https://travis-ci.org/tdiary/rpaproxy-sinatra.svg?branch=master)](https://travis-ci.org/tdiary/rpaproxy-sinatra)
[![Code Climate](https://codeclimate.com/github/tdiary/rpaproxy-sinatra.png)](https://codeclimate.com/github/tdiary/rpaproxy-sinatra)
[![Dependency Status](https://gemnasium.com/tdiary/rpaproxy-sinatra.png)](https://gemnasium.com/tdiary/rpaproxy-sinatra)

## なにこれ？

Amazon Web ServicesのProduct Advertising API用の認証処理を代行するプロキシ(amazon-auth-proxy仕様準拠)の負荷分散を行うリバース・プロキシです。

上記のエンドポイント宛にProduct Advertising API（旧：Amazon アソシエイト Web サービス）のRESTエンドポイント用クエリを付けて送信すると、登録されているプロキシの中からラウンドロビンに選択して要求を中継し、応答を返します。

# Install and running on Docker

Build the docker image.

```
$ git clone git@github.com:tdiary/rpaproxy-sinatra.git
$ docker build -t tdiary/rpaproxy .
```

## Running rpaproxy in development environment.

Start a mongodb container. This container is taken from official mongodb image.

```
$ docker run -d --name mongodb1 mongo
```

Start the reverse proxy app.

```
$ docker run --rm -p 80:3000 --link mongodb1:mongodb tdiary/rpaproxy
```

Then, access it via `http://localhost:80` in a browser.

## Running rpaproxy in development environment.

You can run rpaproxy with docker-compose simply.

```
$ export TWITTER_KEY=your_twitter_key
$ export TWITTER_SECRET=your_twitter_secret
$ docker-compose up
```

Or, you can also run rpaproxy manually (without docker-compose).

```
$ export TWITTER_KEY=your_twitter_key
$ export TWITTER_SECRET=your_twitter_secret
$ docker run -d --name mongodb1 mongo
$ docker run -d --name memcached1 memcached
$ docker run --rm -p 80:3000 -e RACK_ENV=production -e MEMCACHE_SERVERS=memcached:11211 -e TWITTER_KEY -e TWITTER_SECRET --link memcached1:memcached --link mongodb1:mongodb tdiary/rpaproxy
```
