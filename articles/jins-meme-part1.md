---
title: "JiNS MEME で良い姿勢をキープする"
emoji: "👓"
type: "tech"
topics: ["MEME","IoT"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false
---


## はじめに

今年の10月（2021/10）にJINSからメガネ型のウェアラブル端末｢JINS MEME｣の新型が発売されました。｢JINS MEME｣とは、メガネの鼻当て部分にCOREという2つのセンサーを搭載したウェアラブルデバイスで、このセンサーがスマートフォンアプリとbluetoothで連携することで様々な機能を提供してくれる「ココロとカラダのセルフケアメガネ」というコンセプトのデバイスです。
詳しくはこんな感じ（https://jinsmeme.com ）


今回発売された新型MEMEは、SDKは提供されないもののセンサーデータは公式のLoggerアプリやWebAPIを通じてDeveloper向け公開されており、取得し活用することができるようになっています。

前置きが長くなりましたが、本記事はこのJINS MEMEのセンサーデータを取得して、スマートライト（Philips Hue）と連携させて姿勢の監視をしてみます。


## 作るもの

RaspberryPiに立てた Node-Red をハブにして、MEMEのセンサーデータ取得からデータを元にPhilips Hueの明かりを変化させます。

＜図を貼ります＞


# Raspberry pi のセットアップ

## OSインストール

1. [こちら](https://www.raspberrypi.com/software/)から Raspberry Pi ImagerをDL します

2. PCにmicro SDカードを挿入します

3. Raspberry Pi Imager を実行し `command` + `shift` + `x` で Advanced Option設定画面を表示し任意の値を設定していきます。主な設定箇所は以下のようになります
   * Set hostname
   * Enable SSH
   * Set local Settings
![](https://storage.googleapis.com/zenn-user-upload/70d265463005-20211123.png)
4. OSにRaspberry Pi OS、ストレージに挿入済みのSDカードを選択しイメージを書き込みます
![](https://storage.googleapis.com/zenn-user-upload/609e359f196c-20211123.png)

## Node-Redインストール

センサーデータの収集と、外部のスマートライトとの連携のために、ビジュアルプログラミングツール [Node-Red](https://nodered.org) を活用するため、これを導入します。


1. sshでRaspberryPiに接続します（予めDHCPでIPアドレスが割り振られるようにしておきます）
1. Node-Redには便利なインストールコマンドがあるので、これを実行します
```bash
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
```
質問にはいずれも `y` で回答しておきます  
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/88184/788d7e39-178a-d73a-9600-2a91867fcf86.png)
1. `node-red-start` コマンドでNode-Redを起動し、http://`<server-ip/host>`:1880 にアクセスし起動状態を確認します


# JINS MEME センサー情報の受信

iOS アプリ JINS MEME Logger の導入を行い、自分のJINS MEMEデバイスと接続していきます。  

## Step1. JINS MEME Loggerアプリの設定


1. App Storeから [JINS MEME Logger](https://apps.apple.com/jp/app/jins-meme-logger/id1537937129)アプリをインストールします（120円かかります）
1. JINS MEME Logger を起動し、検索 ボタンにてMEMEを探し接続。接続ができると、JINS MEME Loggerアプリ上でログが確認できます  
端末を見つけ接続
![](https://storage.googleapis.com/zenn-user-upload/9cfb0573e912-20211123.png =350x)
ログの表示
![](https://storage.googleapis.com/zenn-user-upload/602c794cf17f-20211123.png =350x)


※ JINS Platformで提供されている簡易WebSocketサーバ利用したい場合、こちらの記事をご覧ください


## Step2. RaspberryPi上のWebSocketサーバでセンサーデータを受信する

Node-Redでは、様々な機能を持ったノードを連結させて1つのフローを構成し複雑な機能を実現できます。
Step1 で導入した JINS MEME Logger からのデータを Node-RedのWebSocket受信機能で受け取るため、まずはWebSocket受信用のノードと、結果を表示させるDebug用のノードだけのシンプルな構成でデータ受信を試していきます。

1. データ受信のための `WebSocket in` のノードと、Debugノードを配置し、それぞれを連結させます  
![](https://storage.googleapis.com/zenn-user-upload/a8b326e1066d-20211123.png)
プロパティには以下のように設定しておきます  
![](https://storage.googleapis.com/zenn-user-upload/b0205913b6de-20211123.png =350x)
1. 続いて、送信側となる iPhoneの JINS MEME Logger アプリを起動し、下部メニューの`設定` から WebSocketクライアント を追加します（ポート番号はNode-Redの環境に合わせて設定します）
![](https://storage.googleapis.com/zenn-user-upload/1b21caa45b69-20211123.png =350x)
1. Debugノードにて、jsonログが受信できていることを確認します
![](https://storage.googleapis.com/zenn-user-upload/d6f4813ec408-20211123.gif)

これで、JINS MEMEのセンサーデータを受信して活用していくための下準備が整いました。次の章では取得したセンサーデータを可視化するダッシュボードを作っていきます。


# センサー情報の可視化

RaspberryPiは、Pluginによって機能拡張することができます。Plug-inの中には、様々なデータを簡易に可視化するダッシュボード機能もあります。取得したデータを見やすく表示するため簡単なダッシュボードを作っていきます。

## Step1. Node-Red に node-red-dashboard plug-in を追加

1. Node-Red画面右上のメニューから `パレットの管理` を選択し、`ノードの追加`タブから "node-red-dashboard" という文字列で検索を行い、該当する結果の右下の `ノードの追加` ボタンを押し機能をインストールします
![](https://storage.googleapis.com/zenn-user-upload/22e8f87bdf5d-20211123.png =350x)
![](https://storage.googleapis.com/zenn-user-upload/bae015ff60ba-20211123.png)
2. インストールが完了したら、RaspberryPiのターミナルで `node-red-restart` コマンドを実行し Node-Redを再起動します
3. インストールに成功すると、画面左のノード一覧にDashboard用のノードが出現します
![](https://storage.googleapis.com/zenn-user-upload/bb01ebbecc0f-20211123.png =250x)

## Step2. ダッシュボードの追加

前章まで取得可能となったデータを元に、ダッシュボードに可視化を行うフローを作成していきます。

1. WebSocketサーバからの受信データは msg.payload にJavascriptオブジェクトとして保持しているためこれをJSON文字列にパースするため`json`ノードを追加します
![](https://storage.googleapis.com/zenn-user-upload/7b9afdad7552-20211123.png)
2. パースしたJSON文字列から、まずは頭の左右の傾きに関するメトリクス `accX` を取得します。Dashboardに渡すため、`changeノード` をフローに追加し以下のように設定します
![](https://storage.googleapis.com/zenn-user-upload/1a32e7c79fe4-20211123.png)
3. ダッシュボードのレイアウトを作成します。右ペインよりDashboardを選択し、`タブ` を追加任意の名前を設定します。さらに、タブの中に、`グループ`を追加します。今回は、"頭の傾き(左右)"と、"頭の傾き(前後)" を設定しました
![](https://storage.googleapis.com/zenn-user-upload/fa4f656c58c7-20211123.png =350x)
![](https://storage.googleapis.com/zenn-user-upload/a755d8ddd5db-20211123.png)
4. 続いてDashboard用のノードを追加します。今回は可視化の方法としてGaugeとChartoを選びます  
Gauge  
![](https://storage.googleapis.com/zenn-user-upload/348f8c570036-20211123.png)
Chart  
![](https://storage.googleapis.com/zenn-user-upload/abb9c25651e7-20211123.png)
5. 3. 4. の手順を、`accY` についても同様に行います。それらを実施したフローが以下になります
![](https://storage.googleapis.com/zenn-user-upload/640c3584911f-20211123.png)
6. 一旦のDashboardが完成したので、JINS MEME Loggerアプリからセンサーデータを転送し、ダッシュボードの表示を確認します。ダッシュボードは、http://`<RaspberryPi_ip_or_host>`:`<port>`/ui にアクセスすると確認できます。下の例では、左にDashboard、右にJINS MEMEアプリの画面を並べて表示しています。リアルタイムに同じ結果が得られていることがわかります
![](https://storage.googleapis.com/zenn-user-upload/3da50fe6ab47-20211123.gif)
7. さらにメトリクスを加え以下が見られるようにしたフローとDashboardがそれぞれ以下になります
可視化対象
| metrics名     | 説明   | Head |
| ------------- | ------ | ---- |
| accX          | 頭の傾き（左右） | Gauge |
| accX          | ↑  | Chart |
| accY          | 頭の傾き（前後）   | Gauge |
| accY          | ↑   | Chart |
| blinkSpeed    | まばたき速度   | Chart |
| blinkStrength | まばたき強さ   | Chart |
| eyeMoveUp     | 目線の移動（上）   | Chart |
| eyeMoveDown   | 目線の移動（下）   | Chart |
| eyeMoveLeft   | 目線の移動（左）   | Chart |
| eyeMoveRight  | 目線の移動（右）   | Chart |
フロー定義
![スクリーンショット 2021-11-23 14.02.30.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/88184/bd1435db-9d4c-d69c-c29c-3c26b6a4f57b.png )
ダッシュボード  
![スクリーンショット 2021-11-23 13.50.20.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/88184/afa5992f-bcc5-1604-016f-e9516d0061c1.png)


# センサー情報の活用

JINS MEMEのセンサー情報を収集できるようになったので、次は収集したデータを元に


# References
本記事を書くにあたって参考にさせていただきました

* https://ipsj.ixsq.nii.ac.jp/ej/index.php?active_action=repository_view_main_item_detail&page_id=13&block_id=8&item_id=184500&item_no=1
* http://yuichi-dev.blogspot.com/2017/02/jinsjins-meme-philips-hue.html