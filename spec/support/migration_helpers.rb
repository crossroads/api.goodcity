module MigrationHelpers

  def load_migration(migration_filepath)
    MigrationSpecInstance.new(migration_filepath)
  end

  def open_table(table_name)
    SQLInspector.new(table_name.to_s)
  end

  private

  class SQLInspector
    def initialize(table_name)
      @table_name = table_name
    end

    def column_type(column)
      res = ActiveRecord::Base.connection.execute <<-SQL
        SELECT data_type
        FROM information_schema.columns
        WHERE table_name = '#{@table_name}' and column_name = '#{column.to_s}'
      SQL
      res.first ? res.first['data_type'] : nil
    end

    def has_column?(column)
      column_type(column).present?
    end

    def column_value(id, column)
      res = ActiveRecord::Base.connection.execute <<-SQL
        SELECT #{column}
        FROM #{@table_name}
        WHERE id = #{id}
      SQL
      return res.first[column]
    end

    def count
      res = ActiveRecord::Base.connection.execute("SELECT COUNT(id) FROM #{@table_name}");
      return res.first['count'].to_i
    end

    def row(id)
      ActiveRecord::Base.connection.execute("SELECT * FROM #{@table_name} WHERE id = #{id}").first
    end

    def new_row
      SQLRowBuilder.new(@table_name)
    end
  end

  class SQLRowBuilder
    def initialize(table_name)
      @table_name = table_name
      @attributes = {}.with_indifferent_access
    end

    def string(key, value)
      @attributes[key] = "'#{value.to_s}'"; self
    end

    def integer(key, value)
      @attributes[key] = value.to_i; self
    end

    def boolean(key, value)
      @attributes[key] = value == true ? 'TRUE' : 'FALSE'; self
    end

    def time(key, value)
      @attributes[key] = "'#{value.to_s(:db)}'"; self
    end

    def timestamps
      time(:updated_at, Time.now)
      time(:created_at, Time.now)
    end

    def build
      columns = @attributes.keys.map(&:to_s)
      values  = columns.map { |c| @attributes[c] }
      
      res = ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO #{@table_name} (#{columns.join(',')})
        VALUES (#{values.join(',')})
        RETURNING *
      SQL
      res.first
    end
  end
  
  class MigrationSpecInstance
    def initialize(filename)
      require(Rails.root.join('db/migrate/' + filename))

      @version, *words = filename.split('_')
      @migration_class = words.join('_').camelize.constantize
      @migration = @migration_class.new
    end

    def has_run?
      table_name  = ActiveRecord::SchemaMigration.table_name
      query       = "SELECT version FROM %s WHERE version = '%s'" % [table_name, @version]
      ActiveRecord::Base.connection.execute(query).any?
    end

    def silently
      initial = ActiveRecord::Migration.verbose
      ActiveRecord::Migration.verbose = false
      yield
    ensure
      ActiveRecord::Migration.verbose = initial
    end

    def up
      silently { @migration.migrate(:up) }
    end

    def down
      silently { @migration.migrate(:down) if has_run? }
    end
  end
end
