pub fn convert_int_to_bool(value: Int) -> Bool {
  when value is {
    0 -> False
    _ -> True
  }
}
