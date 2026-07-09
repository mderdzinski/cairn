# Cairn

A quiet iOS and watchOS app for noticing what you feel and returning to reflect on it later.

**Site:** [noticedaily.com](https://noticedaily.com)
**Status:** v1.0, in App Store review.

## What Cairn is

Most of what we feel passes without a mark. Cairn is a small practice for changing that.

You capture a moment in a second. One of six categories (contentment, desire, aversion, restlessness, heaviness, doubt), one tap on your watch or phone. No typing, no forms, nothing that takes you out of the moment you noticed.

Later, Cairn invites you back to reflect.

Over time, the stones form a path you can read. Not a score. Not a streak. Just what you noticed, laid out so you can see it.

## Stack

- iOS and watchOS, native, Swift with SwiftUI and WatchKit.
- Local-first with SwiftData for persistence.
- CloudKit for sync across your own Apple devices. No backend.
- CairnCore, a small Swift package with the model, aggregates, and colors, shared by both platforms.
- A design system with warm-stone neutrals and a grounded sage green. See `/tokens` in the sibling [`cairn-site`](https://github.com/mderdzinski/cairn-site) repo.

## Layout

```
Cairn/                     iOS app target
Cairn Watch App/           watchOS app target
Cairn Watch Widgets/       accessory-family complications
Packages/CairnCore/        shared Swift package (model + aggregates)
```

## Building

- Xcode 26.5 or newer, iOS 18 and watchOS 11 SDK.
- Fork the repo, open `Cairn.xcodeproj`, and change `DEVELOPMENT_TEAM` in the pbxproj to your own Apple Developer Team ID.
- Cairn uses CloudKit. First run will register a container under your team.

## Contributing

Small personal project, one maintainer, replies may be slow. Bug reports and small fixes are welcome via issues and pull requests. Please open an issue before starting on a larger change so we can agree on scope.

## License

MIT. See [LICENSE](./LICENSE).
