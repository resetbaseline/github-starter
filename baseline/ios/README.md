# Baseline iOS (SwiftUI)

Native **iOS 17+** app targeting Supabase Edge Functions under [`../supabase/`](../supabase/).

## Open the project

- Open **`Baseline.xcodeproj`** in Xcode on macOS (build/run require Xcode; editing Swift on Windows is fine in Cursor).
- **Regenerate** the Xcode project if you change the file list (add/remove Swift files):  
  `node baseline/ios/scripts/generate_xcode_project.mjs`

## Configuration

1. Copy [`Config/Config.example.xcconfig`](Config/Config.example.xcconfig) to **`Config/Config.local.xcconfig`** (gitignored).
2. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` there (or rely on defaults in [`Config/Config.xcconfig`](Config/Config.xcconfig) only for placeholders).
3. [`Config/Config.xcconfig`](Config/Config.xcconfig) is the base xcconfig included by the **Baseline** target; it optionally `#include?`s `Config.local.xcconfig`.

Build settings map those variables into **Info.plist** as `SUPABASE_URL` / `SUPABASE_ANON_KEY` for [`Baseline/Shared/SupabaseClient.swift`](Baseline/Shared/SupabaseClient.swift).

## Dependencies

- **Supabase Swift** SPM: `https://github.com/supabase/supabase-swift` (see `Package.resolved` under the Xcode workspace).

## Theme

Design tokens live in [`Baseline/Theme/Theme.swift`](Baseline/Theme/Theme.swift) (`Theme.Colors`, `Theme.Spacing`, `Theme.Animation`, etc.).
