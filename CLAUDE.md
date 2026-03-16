# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) への指針を提供します。

## プロジェクト概要

これは `rotation_log` という名前のFlutterパッケージで、ログファイルのローテーション機能を提供します。Melosを使用してモノレポとして管理されており、Flutter SDKとDart SDKの管理には `asdf` を使用しています。

## 必須コマンド

### 開発セットアップ

```bash
# プロジェクトのブートストラップ（依存関係のインストール）
melos bootstrap

# すべてのlintチェックを実行（analyze + format）
melos run lint

# 静的解析のみを実行
melos run analyze

# コードをフォーマット
melos run format

# すべてのテストを実行
melos run test

# CIモードでテストを実行（JSON出力）
melos run test-ci

# 単一のテストファイルを実行
cd packages/rotation_log && flutter test test/specific_test.dart
```

### Flutterバージョン管理

- プロジェクトは `asdf` を使用し、バージョンは `.tool-versions` に定義されています
- 現在のFlutterバージョン: `3.41.4-stable`
- Dart SDK: `3.11.1`

## アーキテクチャ

### コード構成

パッケージはDartの `part/part of` パターンを使用し、以下の構造になっています：

- `lib/rotation_log.dart` - パブリックAPIをエクスポートするメインライブラリエントリーポイント
- `lib/src/`:
  - `daily.dart` - 日次ローテーション実装
  - `line.dart` - 行数ベースのローテーション実装
  - `size.dart` - ファイルサイズベースのローテーション実装
  - `logger.dart` - ファイル書き込みとローテーションを処理するコアロガー (`RotationLogger`)
  - `output.dart` - `logger` パッケージとの統合 (`RotationLogOutput`)
  - `rotation.dart` - `RotationOutput` 抽象クラスとファクトリー
  - `term.dart` - ローテーション期間の設定 (`RotationLogTerm`)
  - `options.dart` - ロガー設定 (`RotationLogOptions`, `RotationStructuredLogSchema`)
  - `event.dart` - 構造化ログイベント (`RotationLogEvent`)
  - `plain_text.dart` - プレーンテキストフォーマット設定 (`RotationPlainTextOptions`)
  - `file_info.dart` - ログファイルメタデータ (`RotationLogFileInfo`)

### 主要なデザインパターン

1. **ファクトリーパターン**: `RotationLogTerm` は異なるローテーション戦略のためのファクトリーコンストラクタを提供：
   - `RotationLogTerm.term()` - enumで戦略を指定
   - `RotationLogTerm.day(int)` - カスタム日数でのローテーション
   - `RotationLogTerm.line(int)` - 行数ベースのローテーション
   - `RotationLogTerm.size(int)` - ファイルサイズベースのローテーション（バイト）
   - `RotationLogTermEnum.daily/week/month` - 日次・週次・月次のプリセット

2. **ストラテジーパターン**: `RotationOutput` 抽象クラスを `DailyOutput`、`LineOutput`、`SizeOutput` が実装。`RotationOutput.fromTerm()` ファクトリーで戦略を生成

3. **統合パターン**: `RotationLogOutput` (`LogOutput` サブクラス) が `logger` パッケージと統合。プレーンテキストまたは構造化JSON形式でログ出力

### コアクラス

- `RotationLogger`: ログの書き込み・ローテーション・アーカイブを管理するメインクラス
- `RotationLogOutput`: `logger` パッケージとの統合ポイント
- `RotationLogTerm`: ローテーション間隔の設定
- `RotationLogOptions`: ディレクトリ名、ファイル名プレフィックス、ログレベル、構造化ログ設定など
- `RotationLogEvent`: 構造化ログの1イベント（level, message, tags, context, error, stackTrace）
- `RotationPlainTextOptions`: プレーンテキストフォーマットのカスタマイズ（タイムスタンプパターン等）
- `RotationLogFileInfo`: ログファイルのメタデータ（パス、サイズ、更新日時、現在のセッションか等）
- `RotationStructuredLogSchema`: 構造化ログのJSONキー名のカスタマイズ

## テストアプローチ

- ユニットテストは `packages/rotation_log/test/` にあります
- テストは時間のモックに `clock` パッケージを使用
- パスプロバイダーは `setMockMethodCallHandler` を使用してモック化
- 特定のテストの実行: `cd packages/rotation_log && flutter test test/[test_file].dart`

## コード品質基準

プロジェクトは `analysis_options.yaml` を通じて厳格なlintルールを適用：

- 暗黙的なキャストや動的型の禁止
- パッケージインポートの必須化
- パブリックAPIのドキュメント必須
- 文字列にはシングルクォートを使用
- 待機していないFutureはエラー

## CI/CD

GitHub Actionsワークフローが実行：

1. Lintチェック (`melos run lint`)
2. カバレッジレポート付きユニットテスト
3. `asdf` でFlutter/DartをセットアップするカスタムGitHub Actionを使用
4. 高速ビルドのための依存関係キャッシュ

## 重要な実装詳細

1. **ファイルローテーション**: ローテーション時、古いログファイルはマイクロ秒タイムスタンプ付き (`{prefix}-{microseconds}.log`) でリネームされ、新しいアクティブファイル (`{prefix}.log`) が作成されます
2. **セッション管理**: `RotationLogger` はインスタンス生成時に `sessionId`（`{microseconds}-{pid}`）と `sessionStartedAt` を記録し、現在のセッションのファイルを識別できます
3. **アーカイブ**: `archiveLogs()` / `archiveCurrentSessionLogs()` メソッドが `archive` パッケージを使用してログファイルのZIPアーカイブを作成
4. **ログ形式**:
   - プレーンテキスト: `logWithContext()` / `log()` で `RotationPlainTextOptions` に従ってフォーマット
   - 構造化JSON: `logJson()` / `logEvent()` で `RotationLogEvent` をJSONエンコード
5. **ファイル管理API**: `listLogFiles()`、`listLogFileInfos()`、`listCurrentSessionLogFiles()`、`pruneLogs()`、`clearLogs()` でファイルを管理
6. **カスタムディレクトリ**: `directoryProvider` コールバックで任意のディレクトリを指定可能。省略時は `getApplicationSupportDirectory()` 配下の `logs/` を使用
7. **パス管理**: `path_provider` で各プラットフォームに適切なディレクトリを取得
8. **スタックトレース**: `stack_trace` パッケージを使用してスタックトレースを整形
