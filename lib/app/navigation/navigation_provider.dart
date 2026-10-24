import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application-wide navigation index for the shell tabs.
///
/// Defaults to 0 (Home). Any screen can read or write this
/// to switch the active tab — for example, HomeScreen quick
/// actions that navigate to Tasks or Snippets.
final navigationIndexProvider = StateProvider<int>((ref) => 0);
