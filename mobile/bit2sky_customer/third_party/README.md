# Vendored dependencies

## flutter_jailbreak_detection

Vendored from pub.dev 1.10.0. Upstream is unmaintained — last built against
AGP 7.3.1 — and cannot configure under any modern Android Gradle Plugin:

- no `namespace` (required since AGP 8)
- `compileSdkVersion 33`, the spelling AGP 9's DSL no longer reads
- a `package` attribute in the library manifest, removed in AGP 8
- its own pinned AGP 7.3.1 / Kotlin 1.7.20 buildscript
- `minSdk 17`, below AGP 9's floor of 21

Only `android/build.gradle` and `android/src/main/AndroidManifest.xml` are
modified; Dart, Kotlin, and iOS sources are byte-identical to the published
package. The bundled `example/` app and IDE metadata were dropped.

Vendoring rather than patching the pub cache means a fresh clone or a CI runner
builds with no manual setup. It also sidesteps a Windows-specific Gradle failure
("this and base files have different roots") that triggers when the pub cache and
the project sit on different drive letters.

The plugin supplies one boolean — `FlutterJailbreakDetection.jailbroken`, wrapping
RootBeer — consumed by `lib/core/security/device_integrity.dart`. Worth replacing
with a maintained equivalent, or with Play Integrity API, when there's room to
retest the security path.
