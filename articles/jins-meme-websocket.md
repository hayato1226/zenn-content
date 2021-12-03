---
title: "JiNS MEME のセンサーデータを簡易WebSocketサーバで受信する"
emoji: "👓"
type: "tech"
topics: ["MEME","IoT"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false
---

JINS MEME Platformでは、簡易WebSocketサーバによるセンサーデータ受信のサンプルが公開されています。本記事は、その利用方法のメモです。

## JINS MEME Logger 導入

まずは、iOS アプリ JINS MEME Logger の設定を行います。

1. App Storeから [JINS MEME Logger](https://apps.apple.com/jp/app/jins-meme-logger/id1537937129)アプリをインストールします（120円かかります）
1. JINS MEME Logger を起動し、検索 ボタンにてMEMEを探し接続。接続ができると、JINS MEME Loggerアプリ上でログが確認できます  
端末を見つけ接続
![](https://storage.googleapis.com/zenn-user-upload/9cfb0573e912-20211123.png =350x)
ログの表示
![](https://storage.googleapis.com/zenn-user-upload/602c794cf17f-20211123.png =350x)

1. iPhone JINS MEME Platform にある [WebSocket連携](https://jins-meme.github.io/sdkdoc2/logger/websocket_integration.html)ページの`Node.js による WebSocket Serverサンプル ` の内容を使ってWebSocket Serverを起動します（サンプルを index.ts として保存し　↓　のような手順で起動できます）

    ```bash
    npm init -y
    npm install -D typescript @types/node@14 ws
    npx tsc --init
    echo '{
       "compilerOptions": {
       "target": "es2019",
       "module": "commonjs", 
       "sourceMap": true,
       "esModuleInterop": true,
       "forceConsistentCasingInFileNames": true,
       "strict": true,
       "noImplicitAny": false, 
       "skipLibCheck": true 
       }
    }' > tsconfig.json
    npx tsc
    node index.js
    ```

1. JINS MEME Logger の下部のメニューの`設定` から WebSocketクライアント を追加します  
![](https://storage.googleapis.com/zenn-user-upload/422fa21ca77f-20211123.png =350x)
1. RaspberryPi上で起動したnode.js のWebSocketサーバ上で受信したデータが流れ出すのを確認します
![](https://storage.googleapis.com/zenn-user-upload/a59a8de42aaa-20211123.gif)


MEME LoggerからWebSocket経由でRaspberryPiにStreamデータが転送できることが確認できました！
