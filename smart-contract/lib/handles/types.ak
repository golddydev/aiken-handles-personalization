pub type Handle {
  // handle_name
  NFTHandle(ByteArray)
  // handle_name, root_handle_name, subhandle_name
  NFTSubhandle(ByteArray, ByteArray, ByteArray)
  // handle_name, root_handle_name, subhandle_name
  VirtualSubhandle(ByteArray, ByteArray, ByteArray)
}
