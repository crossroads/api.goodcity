class ChineseNameSeparator
  def initialize(mixed_name)
    @mixed_name = mixed_name
  end

  def find_zh_name_index
    # before calling getters check if this method returns true
    @mixed_name.index (/\p{Han}/)
  end

  def get_en_name
    last_index = find_zh_name_index-3
    # last three indexes have: a space,a parenthesis i.e ( and a chinese character
    @mixed_name[0..last_index]
  end

  def get_zh_name
    first_index = find_zh_name_index
    # as last character is '('
    last_index = @mixed_name.size-2
    @mixed_name[first_index..last_index]
  end
end
