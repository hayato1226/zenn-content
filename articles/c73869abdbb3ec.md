---
title: "ザトウクジラの歌を分析する"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["whale-song","analytics"]
published: true
---

# はじめに
冬季に日本近海へ訪れるザトウクジラたちを観察するホエールスイムツアーに参加してきました。
ザトウクジラは、夏はロシア、アラスカ等の高緯度海域で餌を食べ、冬は沖縄・ハワイ等の低緯度海域で繁殖や子育てを行うことが知られています。
ザトウクジラのオスは、繁殖海域では、高音・低音を組み合わせて歌のような独特な鳴き声を発します。歌をうたうクジラはシンガーと呼ばれていて、シンガーの歌はホエールソングと呼ばれています[^1]。
今回のツアーでもシンガーと出会うことができ、長い時には10分ほど歌を聴くことができました。

ホエールソングは独特の構造を持っており、短い音からなる「ユニット（unit）」、ユニットを組み合わせた「フレーズ（phrase）」、複数のフレーズを組み合わせた「テーマ（theme）」、複数のテーマが組み合わされることで一つの「歌」という構成になっています。
同海域のシンガーは類似のパターンの歌をうたったり、年によって流行りのパターン等もあったするそうです。[^2]
こうしたホエールソングの分析には音声データのままではなく、画像データに変換した方が扱い易くなります。今回GoProで撮影した動画を使ってホエールソングの可視化を行ってみました。

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

## 音声データのスペクトログラム

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

画像にすると、フレーズやテーマのまとまりがわかり易くなります

シンガー1 
![mel_spec_audio1](/images/mel_spec_audio1.png)
シンガー2 
![mel_spec_audio2](/images/mel_spec_audio2.png)


音声と合わせて
https://youtu.be/auAZiEr6aP0?si=Ve-XoKYux7JfZxzB

# おわりに
今回、数は少ないながらホエールソングの可視化を行うことでホエールソングの構造を確認し易くしたり別々の歌を見比べることができる様になりました。
また来年は違った歌が流行っているでしょうし、クジラの頭数回復に伴い、歌が繁殖機会を増やすための最適解ではなくなってきている地域もあるそうで[^3] 日本に来るクジラたちにどういう影響があるかも興味深いです。
クジラ達が独自の社会を発達させて、環境に柔軟に対応していく中で歌がどう変化していくか　みたいな所にも注目してホエールウォッチング・スイムを楽しんでいければなと思います！

[^1]: https://churashima.okinawa/sp/userfiles/files/zatoukujira_all_20151127.pdf
[^2]: https://royalsocietypublishing.org/doi/10.1098/rsos.220158
[^3]: https://www.nature.com/articles/s42003-023-04509-7