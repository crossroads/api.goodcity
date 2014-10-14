# Raise an error if an ENV var has been defined in code but not added to .env file
if Rails.env != 'test'

  File.open("#{Rails.root}/.env.sample").each_line do |line|
    key = line.split('=').first
    raise NameError.new("ENV var '#{key}' not declared in .env file. See .env.sample") if key.present? && !ENV.key?(key)
  end

end
