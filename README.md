# Feedify

A Flutter feed with local posts and photo/video stories.

Tap **Add story** above the feed, choose a photo or video, optionally add a
caption, and tap **Share**. Tap a story in the row to view it.

Stories are local to this device. Their metadata and creation timestamps are
stored in shared preferences, and media copies are kept in app storage. Stories
expire 24 hours after sharing. Expiry is checked by a timer while the app runs and
again on launch, resume, and refresh. If the app is closed at expiry, cleanup runs
when it is next opened. The original gallery files are kept.

Run `flutter test` for persistence, expiry, lifecycle, and story UI checks.
