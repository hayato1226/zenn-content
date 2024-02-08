---
title: "ザトウクジラの歌を分析する"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["whale-song","analytics"]
published: true
---

# はじめに
冬季に交尾・出産・子育てのため日本近海へ訪れるザトウクジラたちを観察するホエールスイムツアーに参加してきました。
ザトウクジラは、夏はロシア、アラスカ等の高緯度海域で餌を食べ、冬は沖縄・ハワイ等の低緯度海域で繁殖や子育てを行うことが知られています。
繁殖海域では、オスが高音・低音を組み合わせた独特な鳴き声を発します。歌をうたうクジラはシンガーと呼ばれていて、シンガーの歌はホエールソングと呼ばれています[^1]。
今回のツアーでもシンガーと出会うことができ、10分ほど歌を聴くことができました。

ホエールソングには、短い音からなる「ユニット（unit）」、ユニットを組み合わせた「フレーズ（phrase）」、複数のフレーズを組み合わせた「テーマ（theme）」があり、複数のテーマが組み合わされることで一つの「歌」という構造があります。さらにその歌にも、個体による上手下手があったり、同海域のシンガーは類似のパターンの歌をうたったり、年によって流行りのパターンがあったりするそうです。[^2]
こうしたデータの分析は音声データのままではなく、画像データに変換した方が扱い易くなるので、今回GoProで撮影した動画を使ってホエールソングの可視化を行ってみました。

# ホエールソングの可視化

## 動画からの音声データ抽出

今回の作業は、Apple M1 ChipのMac Miniにて行っています。

[ffmpeg](https://ffmpeg.org)を使って、GoProで撮ったmp4データからmp3データの抽出を行いました。

インストール
```
brew install ffmpeg
```

動画ファイルからの音声データ抽出
```
ffmpeg -i ./2024whale/GX010497.MP4 -ab 256k ./2024whale/GX010497.mp3
```

## 音声データの可視化

可視化には、周波数軸がメル尺度のスペクトログラムであるメルスペクトログラムを利用しました。
Jupyter Lab と Pythonの音響解析および信号処理のライブラリである [Librosa](https://librosa.org/doc/latest/index.html) を利用します。

PythonとJupyter Lab、Linrosaのインストール
```
brew install pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
source ~/.zshrc
pyenv install 3.10.7
pyenv global 3.10.7
pip install jupyterlab
pip install librosa
jupyter lab
```

Jupyter Labで以下を実行して可視化します
```python
import librosa
import librosa.display
import matplotlib.pyplot as plt
import numpy as np

file_name = './2024whale/GX010497.mp3'
y, sr = librosa.load(file_name, sr=None)
S = librosa.feature.melspectrogram(y=y, sr=sr)
S_dB = librosa.power_to_db(S, ref=np.max)

plt.figure(figsize=(90, 10))
librosa.display.specshow(S_dB, x_axis='time', y_axis='mel', sr=sr)
plt.colorbar(format='%+2.0f dB')
plt.title('Mel spectrogram')
plt.tight_layout()
plt.show()
```

# 結果

![mel_spec_audio1](/images/mel_spec_audio1.png)

![mel_spec_audio2](/images/mel_spec_audio2.png)


音声と合わせて
https://youtu.be/auAZiEr6aP0?si=Ve-XoKYux7JfZxzB

# おわりに
今回、数は少ないながらホエールソングの可視化を行うことでユニット・フレーズ・テーマから成ると言うホエールソングの構造を確認したり２頭分の歌を見比べることができる様になりました。
また来年は違った歌が流行っているでしょうし、クジラの頭数回復に伴い、歌が繁殖機会を増やすための最適解ではなくなってきている地域もあるそうで[^3] 日本に来るクジラたちにどういう影響があるかも興味深いです。
クジラは独自の複雑な社会を発達させて、周囲の状況に応じて柔軟に変化していく生き物なので、その姿以外に歌にも注目してホエールウォッチング・スイムを楽しんでいければなと思います。

[^1]: https://churashima.okinawa/sp/userfiles/files/zatoukujira_all_20151127.pdf
[^2]: https://royalsocietypublishing.org/doi/10.1098/rsos.220158
[^3]: https://www.nature.com/articles/s42003-023-04509-7