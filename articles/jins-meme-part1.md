---
title: "JINS MEME で良い姿勢をキープしたい"
emoji: "👓"
type: "tech"
topics: ["MEME","IoT"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true
---

# これは何？

JINS MEME を使って、姿勢が悪くなったらライトの色で教えてくれるヤツを作ってみた という記事です。  
[NSSOL Advent Calendar 2021](https://qiita.com/advent-calendar/2021/nssol) 7日目の記事になります。

# はじめに

2021/10 JINSからウェアラブル端末｢JINS MEME｣の新型が発売されました。｢JINS MEME｣は、メガネの鼻当て部分にセンサーを搭載したウェアラブルデバイスで、センサーがスマートフォンアプリと連携して様々な機能を提供してくれる「ココロとカラダのセルフケアメガネ」というコンセプトのデバイスです。
公式サイトの動画をご覧いただくと、詳しいイメージが見られます（https://jinsmeme.com ）。


JINSのウェアラブルデバイスはDeveloper向けのプログラムが充実しており、今回発売された新型MEMEでも、公式のLoggerアプリやWebAPIを通じてセンサーデータを活用できるようになっています。

本記事では、JINS MEMEから取得したセンサーデータを元に良い姿勢が保たれているかを判定し、スマートライト（Philips Hue）の色を変化させることで、専用アプリ無しでも視覚的に自分の状態が分かるようにしてみます。


# 作るもの

RaspberryPi上に立てた Node-Red をハブにして、MEMEから取得したセンサーデータを元にHue BridgeのAPIを呼び出しPhilips Hue Lightの色を変化させます。

![arch](/images/arch.png)

完成品はこんな感じです (メガネの傾きを検知して、ライトの色が青から黄色、赤へと変化します)

https://youtu.be/eEy5QCTcw_E


# 下準備（Raspberry pi のセットアップ）

まずは、センサーデータとスマートライトを接続するハブとなるRaspberry Piをセットアップしていきます。

## OSインストール

1. [こちら](https://www.raspberrypi.com/software/)から Raspberry Pi ImagerをDL します

2. PCにmicro SDカードを挿入します

3. Raspberry Pi Imager を実行し `command` + `shift` + `x` で Advanced Option設定画面を表示し任意の値を設定していきます。主な設定箇所は以下のようになります
   * Set hostname
   * Enable SSH
   * Set local Settings
![](/images/raspi-install-01.png)
4. OSにRaspberry Pi OS、ストレージに挿入済みのSDカードを選択しイメージを書き込みます
![](/images/raspi-install-02.png)

## Node-Redインストール

今回は、センサーデータの収集とスマートライトとの連携のため、ビジュアルプログラミングツール [Node-Red](https://nodered.org) を活用します。まずはこれを導入します。


1. sshでRaspberryPiに接続します（予めDHCPでIPアドレスが割り振られるようにしておきます）
1. Node-Redには便利なインストールコマンドがあるので、これを実行します（質問にはいずれも `y` で回答しておきます ）
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
   ```
   ![](/images/raspi-install-03.png)
1. `node-red-start` コマンドでNode-Redを起動し、http://`<server-ip/host>`:1880 にアクセスし起動状態を確認します


# センサー情報の受信

準備が整ったので、まずは iOS アプリ [JINS MEME Logger](https://apps.apple.com/jp/app/jins-meme-logger/id1537937129) とJINS MEMEデバイスを接続していきます。  

## Step1. JINS MEME Loggerアプリの設定


1. App Storeから [JINS MEME Logger](https://apps.apple.com/jp/app/jins-meme-logger/id1537937129)アプリをインストールします（120円かかります）
1. JINS MEME Logger を起動し、検索 ボタンにてMEMEを探し接続。接続ができると、JINS MEME Loggerアプリ上でログが確認できます  
端末を見つけ接続
![](/images/meme-logger-setup-01.png =350x)
ログの表示
![](/images/meme-logger-setup-02.png =350x)


※ JINS Platformでは、簡易にWebSocket接続を試すためのスクリプトを公開しています。こちらを利用したい場合は、[この記事](https://zenn.dev/hayato1226/articles/jins-meme-websocket)をご覧ください


## Step2. Node-Redでセンサーデータを受信する

Node-Redでは、様々な機能を持ったノードを連結させることで複雑な機能を実現できます。
最初に、Step1 で導入した JINS MEME Logger からのデータを Node-RedのWebSocketサーバで受け取ります。まずはWebSocket受信用のノードと、結果を表示させるDebug用のノードだけのシンプルな構成でデータ受信を試していきます。

1. データ受信のための `WebSocket in` のノードと、結果確認のためのDebugノードを配置し、それぞれ連結させます  
![](/images/node-red-websocket-01.png)
プロパティには以下のように設定しておきます  
![](/images/node-red-websocket-02.png =350x)
1. 続いて、送信側となる iPhoneの JINS MEME Logger アプリを起動し、下部メニューの`設定` から WebSocketクライアント を追加します（ポート番号はNode-Redの環境に合わせて設定します）
![](/images/node-red-websocket-03.png =350x)
1. Debugノードにて、jsonログが受信できていることを確認します
![](/images/node-red-websocket-04.gif)

これで、JINS MEMEのセンサーデータを受信できるようになりました。次はデバッグログ出力から少し進化させて、取得したセンサーデータを可視化するダッシュボードを作っていきます。


# センサー情報の可視化

Node-Red は、初期から使えるコアノードの他に、サードパーティノードを追加する事で簡単に機能拡張することができます。ノードの中には、様々なデータを簡易に可視化するダッシュボード機能を持つものもあります。  
これを活用して、前項までで取得したデータを見やすく表示するため簡単なダッシュボードを作っていきます。

## Step1. Node-Red に node-red-dashboard plug-in を追加

1. Node-Red画面右上のメニューから `パレットの管理` を選択し、`ノードの追加`タブから "node-red-dashboard" という文字列で検索を行い、該当する結果の右下の `ノードの追加` ボタンを押し機能をインストールします
![](https://storage.googleapis.com/zenn-user-upload/22e8f87bdf5d-20211123.png =350x)
![](https://storage.googleapis.com/zenn-user-upload/bae015ff60ba-20211123.png)
2. インストールが完了したら、RaspberryPiのターミナルで `node-red-restart` コマンドを実行し Node-Redを再起動します
3. インストールに成功すると、画面左のノード一覧にDashboard用のノードが出現します
![](https://storage.googleapis.com/zenn-user-upload/bb01ebbecc0f-20211123.png =250x)

## Step2. ダッシュボードの追加

前章まで取得可能となったデータを元に、ダッシュボードに可視化を行うフローを作成していきます。

1. WebSocketサーバからの受信データは msg.payload にJavascriptオブジェクトとして保持されています。まずはこれをJSON文字列にパースするため`json`ノードを追加します
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
6. JINS MEME Loggerアプリからセンサーデータを転送し、ダッシュボードの表示を確認します。ダッシュボードは、http://`<RaspberryPi_ip_or_host>`:`<port>`/ui にアクセスすると確認できます。下の例では、左にDashboard、右にJINS MEMEアプリの画面を並べて表示しています。リアルタイムに同じ結果が得られていることがわかります
![](/images/dashboard_meme_1080p.gif =640x)


# スマートライトと繋げる

JINS MEMEのセンサーとNode-Redを連携させ、センサデータを取得できるようになったので、
次はNode-RedからHueに命令を送れるように設定していきます。

## Step1. Philips Hue Bridge API接続用設定の取得

まずは、Philips Hue BridgeとNode-Redを連携させるため、API Keyを発行します

1. Hue Bridgeの設定を行うため、ブラウザでCLIP API Debugger（`http://<hue_bridge_ip>/debug/clip.html`）へアクセスします
![](/images/clip_api_debugger.png =350x)
2. Hue Bridgeのリンクボタンを押したうえで、以下の通りリクエストを発行します。そうすると、Responseで、キー：username の値として API Keyが発行されます。
   * URL: /api
   * POST
   * Message Body: `{"devicetype": "my_hue_app"}`  ※　値は任意です
![](/images/get_api_key.png =350x)
3. api key を使って以下の通り入力し、Hue Lightの一覧を取得してみます
   * URL: `/api/<api-key>/lights`
   * GET
![](/images/get-lights.png =350x)

（より詳細な CLIP API Debuggerの使い方は[Get Started - Philips Hue Developer Program](https://developers.meethue.com/develop/get-started-2/) の記事をご覧ください ）

## Step2. Node-Red と Philips Hue Bridge の接続

続いて Node-Red に ノード "[node-red-contrib-huemagic](https://flows.nodered.org/node/node-red-contrib-huemagic)" を追加し、Hue Bridgeと接続します。


1. パレット > ノードを追加　から install-node-red-contrib-huemagic を検索し導入します
![](/images/install-node-red-contrib-huemagic.png)
2. HueMagicのノードから、Hue Lightを選択し、フローに配置します
![](/images/huemagic-pallet.png =200x)
3. Hue Lightノードをダブルクリックし、Hue Lightノードのプロパティ設定画面の Bridgeから、「新規にHue Bridgeを追加」を選択しブリッジ追加画面へ進み以下の通り設定し「追加」します
    * Name: 任意の名前を入力
    * Bridge IP: 虫メガネのアイコンをクリックして LAN内のHue Bridgeを検索し選択
    * API Key: Step1 で生成したAPI Key
![](/images/add-hue-bridge.png =350x)
4. 再びHue Lightノードのプロパティ設定画面へ戻り、以下の通り設定します
    * Name: 任意の名前を入力
    * Bridge: 3. で追加したBridge
    * Light: 今回利用するライトを選択
![](/images/hue-light-property.png)

以上で、Node-Red から Hue Bridge経由でスマートライトの点灯や色の変更などができるようになりました

## Step3. Hue Lightの制御をフローに組み込む

最後のステップとして、ダッシュボードを表示させたフローに追加でHue Lightの制御を組み込んでいきます。
今回は、簡略化して　前後の頭の傾きを姿勢の良さの指標に使っていきます（多くのメトリクスを組み合わせたより精緻な判定は今後検討していきます）。  
完成図はこんな感じです。順を追って要素ごとに解説していきます。

![](/images/flow-over-view.png)


### Rate Limit の設定
API の呼び出し数が過剰になり過ぎないよう流量制御のノードを全段に配置します。1秒に1度だけメッセージを通過させて、その他のメッセージは破棄するよう以下のように設定します。

![](/images/rate-limit.png =350x)

###  メトリクスの判定
流れてきたメトリクスの値によって、その後に呼び出すノードを切り替えるため Switch ノードを使い以下のように設定します。
絶対値が 7以上になったら 1 or 2 のノードへ、6未満3以上の場合 3 or 4 のノードへ、3未満の場合 5 のノードへ遷移するように設定しました。
![](/images/switch-node.png =350x)

ノード間を以下のように接続します

![](/images/switch-color-by-metrics.png =600x)


### Hue Lightの点灯
姿勢の良し悪しをライトの色で通知します。メトリクスの判定で実施したSwitchノード設定に合わせて、以下のようにChangeノードのpayload に設定することで、ライトを点灯させます。
* 1 or 2 -> 赤く点灯 : `{"on":true,"brightness":100,"hex":"A60000"}`
* 3 or 4 -> 黄色く点灯: `{"on":true,"brightness":100,"hex":"E5BF00"}`
* 5 -> 青く点灯: `{"on":true,"brightness":100,"hex":"6666ff"}`
![](/images/set-light-color.png =350x)

ノード間を以下のように接続します

![](/images/set-light-color-on.png =600x)

# 完成！

完成品を動かすとこんな感じになります！

https://youtu.be/eEy5QCTcw_E

# おわりに

今回、JINS MEMEのセンサーデータをスマートデバイスを連携させて姿勢チェックに使ってみました。簡単化のために利用するメトリクスやデバイスも最小限のものに限って実施しましたが、JINS MEMEには他にも色々なデータが取得できます。また、簡単に連携可能なスマートデバイスも巷に沢山存在しています。
次は活用するメトリクスや連携するデバイスのバリエーションを増やしたり、分析ロジックをもっと賢くリッチにしたり、と色々トライしてみたいと思います！


# References
本記事を書くにあたって大変大変 参考にさせていただきました m(_ _)m

* [アイウェアによる集中力センシングに基づいた行動変容システムの設計](https://ipsj.ixsq.nii.ac.jp/ej/index.php?active_action=repository_view_main_item_detail&page_id=13&block_id=8&item_id=184500&item_no=1)
* http://yuichi-dev.blogspot.com/2017/02/jinsjins-meme-philips-hue.html