class ComputableNumeric < Numeric
  attr_accessor :__value

  def compute
    raise NotImplementedError
  end

  def to_i
    @__value ||= compute
  end

  def to_s
    to_i.to_s
  end

  def coerce(other)
    return [other, self] if other.is_a?(ComputableNumeric)

    new_obj = ComputableNumeric.new
    new_obj.__value = other.to_i
    [new_obj, self]
  end

  def <=>(other)
    to_i <=> other.to_i
  end

  def +(other)
    @value = to_i + other.to_i
  end

  def -(other)
    @value = to_i - other.to_i
  end

  def *(other)
    @value = to_i * other.to_i
  end

  def /(other)
    @value = to_i / other.to_i
  end

  def self.from_i(num)
    cn = ComputableNumeric.new
    cn.__value = num
    cn
  end
end