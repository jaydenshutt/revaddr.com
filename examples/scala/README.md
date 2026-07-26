# Scala sample

```bash
export REVADDR_API_KEY="sk_live_..."
# With scala-cli (https://scala-cli.virtuslab.org/):
scala-cli Reverse.scala
scala-cli Reverse.scala -- 37.7749 -122.4194
```

Uses the JDK `HttpClient` (same stack as many JVM data pipelines). For production, parse JSON with circe or uPickle and keep `match_type` / `distance_meters` for quality gates.
