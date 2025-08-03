# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) への指針を提供します。

## プロジェクト概要

これは `rotation_log` という名前のFlutterパッケージで、ログファイルのローテーション機能を提供します。Melosを使用してモノレポとして管理されており、Flutter SDKの管理にはFVM (Flutter Version Manager) を使用しています。

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
- プロジェクトはFVMを使用し、Flutter SDKは `.fvm/flutter_sdk` にあります
- 必要なFlutterバージョン: >= 3.32.0
- Dart SDK: >= 3.8.0 < 4.0.0

## アーキテクチャ

### コード構成
パッケージはDartの `part/part of` パターンを使用し、以下の構造になっています：

- `lib/rotation_log.dart` - パブリックAPIをエクスポートするメインライブラリエントリーポイント
- `lib/src/`:
  - `daily.dart` - 日次ローテーション実装
  - `line.dart` - 行数ベースのローテーション実装
  - `logger.dart` - ファイル書き込みとローテーションを処理するコアロガー
  - `output.dart` - 出力処理とファイル操作
  - `rotation.dart` - 基本ローテーションロジック
  - `term.dart` - ローテーション期間の設定

### 主要なデザインパターン

1. **ファクトリーパターン**: `RotationLogTerm` は異なるローテーション戦略のためのファクトリーコンストラクタを提供：
   - `RotationLogTerm.term()` - カスタム期間
   - `RotationLogTerm.day()` - 日次ローテーション
   - `RotationLogTerm.week()` - 週次ローテーション
   - `RotationLogTerm.month()` - 月次ローテーション
   - `RotationLogTerm.line()` - 行数ベースのローテーション

2. **ストラテジーパターン**: 異なるローテーション戦略が基本ローテーションロジックを異なる方法で実装

3. **統合パターン**: パッケージは `RotationLogOutput` クラスを介して人気のある `logger` パッケージと統合

### コアクラス

- `RotationLog`: ログの書き込みとローテーションを管理するメインクラス
- `RotationLogOutput`: `logger` パッケージとの統合ポイント
- `RotationLogTerm`: ローテーション間隔の設定
- `RotationLineLog`: 行数に基づく代替ローテーション

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
3. FVMサポート付きカスタムFlutterアクションを使用
4. 高速ビルドのための依存関係キャッシュ

## 重要な実装詳細

1. **ファイルローテーション**: ローテーション時、古いログファイルはタイムスタンプ付きでリネームされ、新しいファイルが作成されます
2. **アーカイブ**: `download()` メソッドは `archive` パッケージを使用してログファイルのZIPアーカイブを作成
3. **エラーハンドリング**: Flutterエラーキャプチャのために `runZonedGuarded` と統合
4. **パス管理**: 各プラットフォームで適切なディレクトリを取得するために `path_provider` を使用
5. **スタックトレース**: `stack_trace` パッケージを使用してスタックトレースを見やすく整形