auto_fan
========

[WEMO](http://www.belkin.com/us/wemo) の先に接続されたファンの ON/OFF を，ネットワークの混み具合や温度に基づいて制御するスクリプトです．

モチベーション
--------------

ここだけの話，NEC の [AtermWG1800HP](http://121ware.com/product/atermstation/product/warpstar/wg1800hp/) は，室温が 30 ℃近くなった環境で高速通信を行うと，熱暴走してしまいます．これを回避するためには強制空冷するしかありません．

常時ファンを回し続けるのも無駄なので，高速通信を行っているときのみファンを動かすようにするために，このスクリプトを作成しました．

必要なもの
----------

ネットワークの混み具合の確認に下記のものを使用しています．

+ SSH
+ dstat

温度の確認に下記のものを使用しています．

+ [USBRH](http://green-rabbit.sakura.ne.jp/usbrh/)

WEMO の制御に下記のものを使用しています．

+ [ouimeaux](https://github.com/iancmcc/ouimeaux)
