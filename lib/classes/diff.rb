class Diff

  include Comparable
  attr :id, :diff, :name

  def initialize(name, a, b, attrs)
    # name and id so we can make reference to an obj in output diff
    @name = name
    @a = a # GoodCity
    @b = b # Stockit
    @attrs = attrs
    @diff = {}
    @id = @a.id || 0
  end

  # Generates a key per diff (based on id and stockit_id)
  # def key
  #   "#{@a.id}:#{@a.stockit_id}:#{@b.id}"
  # end

  # compares two objects and returns self to enable deeper introspection
  def compare
    @attrs.each do |attr|
      next if %w(id stockit_id).include?(attr.to_s)
      x = @a[attr] || "" # treat nil as blank i.e. nil == ""
      y = @b[attr] || "" # treat nil as blank
      @diff.merge!(attr => [x,y]) if x.to_s != y.to_s
    end
    self
  end

  # StockitActivity=13 | stockit_id=23 | name={bob,steve}
  def in_words
    output = ["#{@name}=#{@a.id}", "other_id=#{@b.id}"]
    if @b.id.nil?
      output << "Missing in Stockit"
    elsif @a.id.nil?
      output << "Missing in GoodCity"
    elsif identical?
      output << "Identical"
    else
      @diff.each { |attr, val| output << "#{attr}={#{val[0]} | #{val[1]}}" }
    end
    output.join(" | ")
  end

  def identical?
    @a.id.present? && @b.id.present? && @diff.empty?
  end

  def <=>(other)
    id <=> other.id
  end

end