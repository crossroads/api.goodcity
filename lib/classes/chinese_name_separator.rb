class ChineseNameSeparator
  def initialize(mixed_name)
    @mixed_name = mixed_name
  end

  def has_zh?
    # before calling getters check if this method returns true
    !(!zh_index)
  end

  def has_en?
    # before calling getters check if this method returns true
    (zh_index-3)==0
  end

  def en
    last_index = zh_index-3
    # last three indexes have: a space,a parenthesis i.e ( and a chinese character
    @mixed_name[0..last_index]
  end

  def zh
    first_index = zh_index
    # as last character is '('
    last_index = @mixed_name.size-2
    @mixed_name[first_index..last_index]
  end

  private
  def zh_index
    # before calling getters check if this method returns true
    @mixed_name.index(/\p{Han}/)
  end
end
