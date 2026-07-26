# Kotlin sample

JVM reverse-geocode using the JDK `HttpClient` (no Gradle required for the CLI demo).

```bash
export REVADDR_API_KEY="sk_live_..."
kotlinc Reverse.kt -include-runtime -d reverse.jar
java -jar reverse.jar
java -jar reverse.jar 37.7749 -122.4194
```

For Android, call `reverseGeocode` from a coroutine on a background dispatcher and store the key in encrypted prefs or a backend proxy.
