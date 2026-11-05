import 'main_local_backend.dart' as local;

// Complete app; normal server authentication, private HTTPS and real native
// Health Connect. The production entry point never imports this wrapper.
Future<void> main() => local.main();
