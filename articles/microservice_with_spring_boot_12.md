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


補足：



## 2. Setting up a config server

設計上の検討事項

backend
* Git repository
* local filesystem
* HashiCorp Vault
* JDBC database
* etc.

本書では単純化のためにLocal filesystemを利用する


個人的には不足点があると思うので、そちらは補遺の章にて


## 3. Configuring clients of a config server

## 4. Structuring the configuration repository

## 5. Trying out the Spring Cloud Configuration server

## 6. 補遺
