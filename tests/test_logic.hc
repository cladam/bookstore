// Title Normalization helper
fun normalize_title(s: string) : string {
  let cs = chars(s)
  let filtered = filter(cs, is_alnum)
  to_lower(from_chars(filtered))
}

test "normalize_title removes spaces and special chars" {
  let r = normalize_title("The Great Gatsby!!!")
  assert(r == "thegreatgatsby")
}

test "normalize_title converts to lowercase" {
  let r = normalize_title("PRIDE AND PREJUDICE")
  assert(r == "prideandprejudice")
}
