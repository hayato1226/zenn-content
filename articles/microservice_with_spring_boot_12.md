---
title: "Microservices with Spring Boot and Spring Cloud 2nd 12章 まとめ"
emoji: 
type: "tech"
topics: ["microservices","spring cloud","spring cloud config"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false
---

増え続けるマイクロサービスのConfigの管理性悪化を解決するために、個別サービスのファイルベースでの管理をやめてSpring Cloud Configuration server を使って中央で集中管理しようという章。

Contents
1. Introduction to the Spring Cloud Configuration server
1. Setting up a config server
1. Configuring clients of a config server
1. Structuring the configuration repository
1. Trying out the Spring Cloud Configuration server
1. 補遺

## 1. Introduction to the Spring Cloud Configuration server

本書のsystem landscape への変更Configを一元管理し他のMSに提供する config server を新たなサービスとして追加する。  
※　先にネタバレしておくと、後々 k8s化した際にはConfigMap/Secret によって置き換える

![](https://dz2cdn1.dzone.com/storage/temp/15084494-1629443126592.png)

以下のAPI Endpointが公開される
* /actuator
    * いつものやつ。本番公開時はロックダウンしておく
* /encrypt, /decrypt
    * 機密情報を暗号化および復号する. 実運用で使用する前にロックダウンしておく
* /{microservice}/{profile}
    * 指定されたマイクロサービスの指定されたSpringプロファイル設定を返す

補足：



## 2. Setting up a config server

### 設計上の検討事項

以下について検討し実装する

(個人的には不足点があると思うので、そちらは補遺の章にて)

#### backend

* Git repository
* local filesystem
* HashiCorp Vault
* JDBC database
* etc.

-> 本書でLocal filesystemを利用する(説明を単純化するためと思われる)

#### initial connection

1. config serverの場所を discoveryサーバから受け取り、Configを読み込む
1. Configを読み込んでから、その情報をもとに discoveryサーバへの問い合わせを行う

どちらも可能。本書では 2.  ただし、config server が1台だとSPOFになるので注意（LB配下に複数台おくんじゃない？）

#### security

* 経路の暗号化はHTTPSでされている
* EPの保護 　
APIユーザーが既知のクライアントであることを保証するためBasic認証を使用
   * SPRING_SECURITY_USER_NAMEとSPRING_SECURITY_USER_PASSWORD

### 実装

1. Spring Initializr などを使ってセットアップする
2. gradle.build へ依存関係の追加
   *  spring-cloud-config-server 
   *  spring-boot- starter-security
4. Application　Classに所定のアノテーション `@EnableConfigServer`　を追加
5. application.yml
```yaml
server.port: 8888
spring.cloud.config.server.native.searchLocations: file:${PWD}/config-repo
management.endpoint.health.show-details: "ALWAYS"
management.endpoints.web.exposure.include: "*"
logging:
  level:
root: info
---
spring.config.activate.on-profile: docker
spring.cloud.config.server.native.searchLocations: file:/config-repo
```
5. routing ruleの追加
   * edge server に設定を追加
   ```yaml
   - id: config-server
     uri: http://${app.config-server}:8888
   predicates:
   - Path=/config/**
   filters:
   - RewritePath=/config/(?<segment>.*), /$\{segment}
   ```
6. Dockerfile・docker-compse の設定
```yaml
config-server:
  build: spring-cloud/config-server
  mem_limit: 512m
  environment:
    - SPRING_PROFILES_ACTIVE=docker,native
    - ENCRYPT_KEY=${CONFIG_SERVER_ENCRYPT_KEY}
    - SPRING_SECURITY_USER_NAME=${CONFIG_SERVER_USR}
    - SPRING_SECURITY_USER_PASSWORD=${CONFIG_SERVER_PWD}
volumes:
    - $PWD/config-repo:/config-repo
```
7. 機密度の高い情報は .env ファイルに移す(dev/test 以外の用途向けには保護しておく)
```
CONFIG_SERVER_ENCRYPT_KEY=my-very-secure-encrypt-key
CONFIG_SERVER_USR=dev-usr
CONFIG_SERVER_PWD=dev-pwd
```
9. settings.gradle に config-server の項を追加


## 3. Configuring clients of a config server

1. build.gradle
   * spring-cloud-starter-config 
   * spring-retry 
2. application.yml の move / rename
3. config-server への接続設定を持った application.yml を追加（2. のものと置き換え）
```yaml
spring.config.import: "configserver:"

spring:
  application.name: product
  cloud.config:
    failFast: true
    retry:
      initialInterval: 3000
      multiplier: 1.3
      maxInterval: 10000
      maxAttempts: 20
    uri: http://localhost:8888
    username: ${CONFIG_SERVER_USR}
    password: ${CONFIG_SERVER_PWD}
---
spring.config.activate.on-profile: docker

spring.cloud.config.uri: http://config-server:8888
```
5. Docker ComposeファイルにBasic認証情報追記
6. 自動テスト（単体テスト）の際には config-server ではなくローカルファイルを見るように設定
```java
@DataMongoTest(properties = {"spring.cloud.config.enabled=false"})

@DataJpaTest(properties = {"spring.cloud.config.enabled=false"})

@SpringBootTest(webEnvironment=RANDOM_PORT, properties= {"eureka.client.enabled=false", "spring.cloud.config.enabled=false"})
```

## 4. Structuring the configuration repository

snip

## 5. Trying out the Spring Cloud Configuration server

実際動かそう


## 6. 補遺

これで十分か？

* 設定変更時の反映はどうする？
* 
