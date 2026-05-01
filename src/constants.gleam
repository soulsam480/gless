import gleam/dict

pub const x_axis = ["a", "b", "c", "d", "e", "f", "g", "h"]

pub const y_axis = ["8", "7", "6", "5", "4", "3", "2", "1"]

pub fn make_rank_to_file() {
  dict.from_list([
    #(1, "a"),
    #(2, "b"),
    #(3, "c"),
    #(4, "d"),
    #(5, "e"),
    #(6, "f"),
    #(7, "g"),
    #(8, "h"),
  ])
}

pub fn make_file_to_rank() {
  dict.fold(make_rank_to_file(), dict.new(), fn(acc, key, value) {
    dict.insert(acc, value, key)
  })
}
