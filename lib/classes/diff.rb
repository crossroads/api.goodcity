class Diff

  include Comparable
  attr :id, :diff, :klass_name

  def initialize(klass_name, goodcity_struct, stockit_struct, sync_attributes)
    # klass_name and id so we can make reference to an obj in output diff
    @klass_name = klass_name
    @goodcity_struct = goodcity_struct
    @stockit_struct = stockit_struct
    @sync_attributes = sync_attributes
    @diff = {}
    @id = @goodcity_struct.id || 0
  end

  # Generates a key per diff (based on id and stockit_id)
  def key
    "#{@goodcity_struct.id}:#{@goodcity_struct.stockit_id}:#{@stockit_struct.id}"
  end

  # compares two objects and returns self to enable deeper introspection
  def compare
    @sync_attributes.each do |attr|
      next if [:id, :stockit_id].include?(attr)
      x = @goodcity_struct[attr] || "" # treat nil as blank i.e. nil == ""
      y = @stockit_struct[attr] || "" # treat nil as blank
      @diff.merge!(attr => [x,y]) if x != y
    end
    self
  end

  # StockitActivity=13 | stockit_id=23 | name={bob,steve}
  def in_words
    output = ["#{@klass_name}=#{@goodcity_struct.id}", "stockit_id=#{@stockit_struct.id}"]
    if identical?
      output << "Identical"
    elsif @stockit_struct.id.nil?
      output << "Missing in Stockit"
    elsif @goodcity_struct.id.nil?
      output << "Missing in GoodCity"
    else
      @diff.each { |attr, val| output << "#{attr}={#{val[0]} | #{val[1]}}" }
    end
    output.join(" | ")
  end

  def identical?
    @diff.empty?
  end

  def <=>(other)
    id <=> other.id
  end

end