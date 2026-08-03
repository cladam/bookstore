// Title Normalization helper
fun normalize_title(s: string) : string {
  let cs = chars(s)
  let filtered = filter(cs, is_alnum)
  to_lower(from_chars(filtered))
}

// Skip Google Docs CSV metadata lines
fun skip_metadata(content: string) : string {
  unlines(drop(lines(content), 2))
}

test "normalize_title removes spaces and special chars" {
  let r = normalize_title("The Great Gatsby!!!")
  assert(r == "thegreatgatsby")
}

test "normalize_title converts to lowercase" {
  let r = normalize_title("PRIDE AND PREJUDICE")
  assert(r == "prideandprejudice")
}

test "skip_metadata drops top two lines" {
  let input = "Meta line 1\nMeta line 2\nHeader,Value\nData1,Data2"
  let r = skip_metadata(input)
  assert(r == "Header,Value\nData1,Data2")
}
