require 'sqlite3'
require_relative 'errors'


 module Selection

   def find(*ids)

    if ids.is_a?(Integer) == false
      if ids.is_a?(Array) == false
       return "Not a valid input."
     end
    end

     if ids.length == 1
       find_one(ids.first)
     else
       rows = connection.execute <<-SQL

       SELECT #{columns.join ","} FROM #{table}
         WHERE id IN (#{ids.join(",")});
       SQL

       rows_to_array(rows)
     end
   end

   def find_one(id)
     if id.is_a?(Integer) == false || id < 0
       return "Not a valid input."
     end

     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE id = #{id};
     SQL

     init_object_from_row(row)
   end

   def find_by(attribute,value)

     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
     SQL

     init_object_from_row(row)
   end

   def method_missing(m, *args, &block)
     method = m.to_s
     arr = method.split("_")
     if method.start_with?("find_by")
       find_by(arr[-1],*args)
     else
      super
     end
   end
   # my_obj.respond_to?("find_by_number")

   def find_each(options= {})
     if options.empty? == true
       sql = <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         LIMIT 200
       SQL
     else
      batch_size = options[:batch_size]
       sql = <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         LIMIT #{batch_size}
       SQL
     end
     puts sql
     rows = connection.execute sql

     rows.each do |row|
       yield(init_object_from_row(row))
     end


   end

   def find_in_batches(start,batch_size)
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE ID >= #{start}
       LIMIT #{batch_size}
     SQL

      yield(rows_to_array(rows))

   end

   def take(num=1)
     if num < 1
       return "Not a valid input."
     end

     if num > 1
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         ORDER BY random()
         LIMIT #{num};
       SQL

       rows_to_array(rows)
     else
       take_one
     end
   end

   def take_one
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT 1;
     SQL

     init_object_from_row(row)
   end

   def first
        row = connection.get_first_row <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          ORDER BY id
          ASC LIMIT 1;
        SQL

        init_object_from_row(row)
      end

      def last
        row = connection.get_first_row <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          ORDER BY id
          DESC LIMIT 1;
        SQL

        init_object_from_row(row)
      end

    def all
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table};
     SQL

     rows_to_array(rows)
   end

   def where(*args)
     if args.count > 1
       expression = args.shift
       params = args
     else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        end
     end

     sql = <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{expression};
     SQL

     rows = connection.execute(sql, params)
     rows_to_array(rows)
   end

   def order(*args)
       args.map! do |arg|
         case arg
         when String
           arg.to_s
         when Symbol
           arg.to_s
         when Hash
           expression_hash = BlocRecord::Utility.convert_keys(arg)
           arg = expression_hash.map {|key, value| "#{key} #{value}"}.join(",")
         end
       end
        order = args.join(",")
     rows = connection.execute <<-SQL
       SELECT * FROM #{table}
       ORDER BY #{order};
     SQL

     rows_to_array(rows)
   end

   def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      sql = <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        sql = <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        sql = <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        puts args.first.keys
        puts args.first.values
        puts table
        sql = <<-SQL
        SELECT * FROM #{table}
        INNER JOIN #{args.first.keys[0]} ON #{args.first.keys[0]}.#{table}_id = #{table}.id
        INNER JOIN #{args.first.values[0]} ON #{args.first.values[0]}.#{args.first.keys[0]}_id = #{args.first.keys[0]}.id
        SQL

      end
    end

    puts sql

    rows = connection.execute sql

    rows_to_array(rows)
  end

   private
   def init_object_from_row(row)
     if row
       data = Hash[columns.zip(row)]
       new(data)
     end
   end

   def rows_to_array(rows)
     collection = BlocRecord::Collection.new
     rows.each { |row| collection << new(Hash[columns.zip(row)]) }
     collection
  end
 end
