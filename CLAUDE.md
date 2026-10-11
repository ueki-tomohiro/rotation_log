# CLAUDE.md

`rotation_log` はログファイルのローテーション（日数・行数・サイズ）、構造化 JSON ログ、ZIP エクスポートを提供する Flutter パッケージ。Melos モノレポで、本体は `packages/rotation_log/`。Flutter/Dart のバージョンは `.tool-versions` が正（ローカルは mise、CI は asdf で同ファイルを読む）。

## コマンド

```bash
melos bootstrap                 # 依存解決
melos run analyze               # dart analyze
melos run format                # dart format packages（ファイルを書き換える）
melos run lint                  # analyze + format。CI と同じ
melos run test                  # example/ を除く全テスト
cd packages/rotation_log && flutter test test/logger_test.dart   # 単体
```

変更後は `melos run lint` と `melos run test` を通すこと（CI は PR で同じものを実行する）。

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

- アクティブファイルは `{prefix}.log`。ローテーション時に `{prefix}-{microseconds}.log` へリネームされる
- `RotationLogger` は生成時に `sessionId`（`{microseconds}-{pid}`）と `sessionStartedAt` を持ち、`listCurrentSessionLogFiles()` / `archiveCurrentSessionLogs()` はこれで現セッションのファイルを判定する
- `directoryProvider` 省略時は `getApplicationSupportDirectory()/{directoryName}`（`RotationLogOptions.directoryName`、既定 `logs`）

## リリース

`packages/rotation_log/pubspec.yaml` の `version` と `CHANGELOG.md` を同じコミットで更新する。`packages/rotation_log/logs/` は生成物で `.pubignore` 済み。
