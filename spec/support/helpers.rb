def scrub(sql)
  sql
  .gsub(/[\"\`]/, '')
  .gsub(/\'t\'/, '1')
  .gsub(/\'f\'/, '0')
end
