# Product Advertising API用リバースプロキシ

[![Build Status](https://travis-ci.org/tdiary/rpaproxy-sinatra.svg?branch=master)](https://travis-ci.org/tdiary/rpaproxy-sinatra)
[![Code Climate](https://codeclimate.com/github/tdiary/rpaproxy-sinatra.png)](https://codeclimate.com/github/tdiary/rpaproxy-sinatra)
[![Dependency Status](https://gemnasium.com/tdiary/rpaproxy-sinatra.png)](https://gemnasium.com/tdiary/rpaproxy-sinatra)

## なにこれ？

Amazon Web ServicesのProduct Advertising API用の認証処理を代行するプロキシ(amazon-auth-proxy仕様準拠)の負荷分散を行うリバース・プロキシです。

上記のエンドポイント宛にProduct Advertising API（旧：Amazon アソシエイト Web サービス）のRESTエンドポイント用クエリを付けて送信すると、登録されているプロキシの中からラウンドロビンに選択して要求を中継し、応答を返します。


