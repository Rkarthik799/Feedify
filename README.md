# Feedify

A Flutter feed for sharing text, photos, and videos, with responsive phone,
tablet, and desktop layouts.

## Run

```sh
flutter pub get
flutter run
```

The feed supports text search, hashtag exploration, and filters for your own
posts and liked posts. The post editor supports media selection, audience
selection, hashtags, mentions, and a confirmation before discarding a draft.

Tap **Comment** on a post to read the conversation or add a comment. Comments
contain an author, timestamp, and up to 1,000 characters. Empty comments are
rejected. Counts come from saved comments, replacing the old dummy counter.
Comments on both sample and user-created posts survive an app restart. If a
save fails, the comment text stays available for retry.

Posts and comments use local shared preferences. There is no backend,
authentication, audience enforcement, or cross-device synchronization. Audience
selection is stored as post metadata. Sample-post likes last for the session;
likes on your own posts are stored with the post. The media progress indicator
simulates local preparation; it does not upload files to a server.

## Check

```sh
flutter analyze
flutter test
```

Tests cover comment validation, persistence, legacy-post compatibility, save
retry, publishing, search, filters, responsive layouts, larger text, and keyboard
insets in portrait and landscape.
