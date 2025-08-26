use aiken/list

pub fn should_check_with_plural_properties(
  plural_keys: List<(ByteArray, ByteArray)>,
  key: ByteArray,
) -> (Bool, ByteArray) {
  let found =
    list.find(
      plural_keys,
      fn(keys) {
        let (_, single_key) = keys
        key == single_key
      },
    )
  when found is {
    Some((plural_key, _)) -> (True, plural_key)
    None -> (False, "")
  }
}

pub fn get_plural_keys() -> List<(ByteArray, ByteArray)> {
  [
    ("bg_border_colors", "bg_border_color"),
    ("bg_colors", "bg_color"),
    ("circuit_colors", "circuit_color"),
    ("pfp_border_colors", "pfp_border_color"),
    ("font_shadow_colors", "font_shadow_color"),
  ]
}

pub fn get_simple_keys() -> List<ByteArray> {
  ["qr_bg_color", "socials_color"]
}

pub fn get_exclusive_keys() -> List<ByteArray> {
  ["text_ribbon_gradient", "font_color", "font", "qr_image"]
}

pub fn get_qr_keys() -> List<ByteArray> {
  ["qr_inner_eye", "qr_outer_eye", "qr_dot"]
}
