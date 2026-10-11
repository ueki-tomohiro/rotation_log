# CLAUDE.md

`rotation_log` はログファイルのローテーション（日数・行数・サイズ）、構造化 JSON ログ、ZIP エクスポートを提供する Flutter パッケージ。Melos モノレポで、本体は `packages/rotation_log/`。Flutter のバージョンは `.tool-versions` が正（ローカル・CI とも mise で管理。Dart は Flutter 同梱のものを使う）。

## コマンド

```bash
melos bootstrap                 # 依存解決
melos run analyze               # dart analyze
melos run format                # dart format packages（ファイルを書き換える）
melos run lint                  # analyze + format。CI と同じ
melos run test                  # example/ を除く全テスト
melos run test-ci               # CI 用。各パッケージに test.json（--machine 出力）を生成
melos run combine               # test.json / lcov を report/ に集約
cd packages/rotation_log && flutter test test/logger_test.dart   # 単体
```

変更後は `melos run lint` と `melos run test` を通すこと。PR の CI は `melos run lint` の後、`melos run test-ci` → `melos run combine` で `report/test.json` を作り、`flutter-test-action` が結果を投稿する。

melos は `dart pub global activate melos 6.3.3` のグローバル版を使う。設定は melos 6 形式の `melos.yaml` にあり、melos 7 以降で動かすと `NoScriptException` になる。

## コード規約

`analysis_options.yaml` の主なポイント：

- `unawaited_futures` はエラー。意図的に待たない場合は `unawaited()` で明示する
- パブリック API には dartdoc 必須（pub.dev のスコアに影響する）
- import は `package:` 形式、文字列はシングルクォート

## ライブラリ構成の注意

`lib/rotation_log.dart` が唯一のライブラリで、`lib/src/*.dart` はすべて `part` ファイル。

- 新しいファイルを足すときは `rotation_log.dart` に `part 'src/xxx.dart';` を追加し、ファイル側は `part of 'package:rotation_log/rotation_log.dart';` とする
- `part` ファイルは import を持てないので、新しい依存の import は `rotation_log.dart` に追加する
- 公開したくないシンボルは `_` プレフィックスにする（`part` 構成なのでライブラリ内では共有される）

## テストの書き方

- ファイル I/O は `directoryProvider: () async => tempDirectory` で一時ディレクトリに向ける（`path_provider` はモックしない）。`tearDown` で削除する
- 時間依存の処理は `clock` パッケージの `withClock(Clock(...), ...)` で制御する。実装側でも `DateTime.now()` ではなく `clock.now()` を使う

## 実装上の挙動（コードを読む前に知っておくと良いこと）

- アクティブファイル名はローテーション方式で異なる
  - `line` / `size`：アクティブファイルは `{prefix}.log`。ローテーション時に `{prefix}-{microseconds}.log` へリネームされる
  - `daily` / `week` / `month` / `custom`：`{prefix}-{microseconds}.log` を直接作成し、期間が過ぎたら新しいファイルを作る（リネームしない）
- `RotationLogger` は生成時に `sessionId`（`{microseconds}-{pid}`）と `sessionStartedAt` を持ち、`listCurrentSessionLogFiles()` / `archiveCurrentSessionLogs()` はこれで現セッションのファイルを判定する
- `directoryProvider` 省略時は `getApplicationSupportDirectory()/{directoryName}`（`RotationLogOptions.directoryName`、既定 `logs`）

## リリース

`packages/rotation_log/pubspec.yaml` の `version` と `CHANGELOG.md` を同じコミットで更新する。`packages/rotation_log/logs/` は生成物で `.pubignore` 済み。
