export 'database_stub.dart'
    if (dart.library.io) 'database_native.dart'
    if (dart.library.js_interop) 'database_web.dart';
