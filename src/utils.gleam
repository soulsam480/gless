import gleam/string

/// positional string formatting
pub fn format(source: String, values: List(String)) -> String {
  case values {
    [] -> source
    [head, ..tail] -> {
      case string.split_once(source, "{}") {
        Ok(#(pre, post)) -> format(pre <> head <> post, tail)
        _ -> source
      }
    }
  }
}
