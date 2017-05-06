class Diff

  include Comparable
  attr :id, :diff

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
      if (x=@goodcity_struct[attr]) != (y=@stockit_struct[attr])
        @diff.merge!(attr => [x,y])
      end
    end
    self
  end

  # StockitActivity=13 | stockit_id=23 | name={bob,steve}
  def in_words
    output = ["#{@klass_name}=#{@goodcity_struct.id}", "stockit_id=#{@stockit_struct.id}"]
    if identical?
      output << "Identical"
    else
      @diff.each { |attr, val| output << "#{attr}={#{val[0]} | #{val[1]}}" }
    end
    output.join(" | ")
  end

  def identical?
    @diff.empty?
  end

  def <=>(other)
    id <=> other.try(:id)
  end

end