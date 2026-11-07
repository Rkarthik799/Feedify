# Feedify

<<<<<<< HEAD
A Flutter feed with local posts and photo/video stories.

Tap **Add story** above the feed, choose a photo or video, optionally add a
caption, and tap **Share**. Tap a story in the row to view it.

Stories are local to this device. Their metadata and creation timestamps are
stored in shared preferences, and media copies are kept in app storage. Stories
expire 24 hours after sharing. Expiry is checked by a timer while the app runs and
again on launch, resume, and refresh. If the app is closed at expiry, cleanup runs
when it is next opened. The original gallery files are kept.

Run `flutter test` for persistence, expiry, lifecycle, and story UI checks.
=======
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
>>>>>>> feature/ui-change
