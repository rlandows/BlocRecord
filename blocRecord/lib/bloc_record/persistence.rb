require 'sqlite3'
 require 'bloc_record/schema'
 require_relative 'errors'


 module Persistence
   def self.included(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
       self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
       BlocRecord::Utility.reload_obj(self)
       return true
     end

     fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

     self.class.connection.execute <<-SQL
       UPDATE #{self.class.table}
       SET #{fields}
       WHERE id = #{self.id};
     SQL

     true
   end

   def update_attribute(attribute, value)
     self.class.update(self.id, { attribute => value })
   end

   def destroy
     self.class.destroy(self.id)
   end

   def method_missing(m, *args, &block)
     puts self.id
     method = m.to_s
     arr = method.split("_")
     if method.start_with?("update_")
       self.class.update(self.id, {arr[-1] => args[0]})
     else
      super
     end
   end

   def update_attributes(updates)
     self.class.update(self.id, updates)
   end

  module ClassMethods
    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(ids, updates)

      if updates.class == Array
        updates.map do |pair|
        idx_val = updates.index(pair)
          updated_pair = BlocRecord::Utility.convert_keys(pair)
          updated_pair.delete "id"
          updated_pair.each do |key, value|
            puts key
            puts value
            set_claus = "#{key}=#{BlocRecord::Utility.sql_strings(value)}"
            connection.execute <<-SQL
              UPDATE #{table}
              SET #{set_claus}
              WHERE id = #{ids[idx_val]};
            SQL

            true
          end
        end
      end
      if updates.class == Hash
        if ids.class == Fixnum
           where_clause = "WHERE id = #{ids};"
         elsif ids.class == Array
           where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
         else
           where_clause = ";"
         end

        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

        connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL

        true
      end
    end

     def update_all(updates)
       update(nil, updates)
     end

     def destroy(*id)
       if id.length > 1
         where_clause = "WHERE id IN (#{id.join(",")});"
       else
         where_clause = "WHERE id = #{id.first};"
       end

        sql = <<-SQL
        DELETE FROM #{table} #{where_clause}
       SQL
       puts sql
       rows = connection.execute(sql)

       true
     end

     def destroy_all(*args)
       if args.count == 1
         case args.first
         when Hash
           args = BlocRecord::Utility.convert_keys(args.first)
           conditions = args.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
         when String
           conditions = args.first
         end
         connection.execute <<-SQL
           DELETE FROM #{table}
           WHERE #{conditions};
         SQL

       elsif args.count > 1
        # args[0] = args.first.split("?")[0]
        # conditions = "#{args[0]}#{BlocRecord::Utility.sql_strings(args[1])}"
        expression = args.shift
        params = args
        sql = <<-SQL
          DELETE FROM #{table}
          WHERE #{expression};
        SQL
        # puts sql
         rows = connection.execute(sql,params)
         rows_to_array(rows)
       else

         connection.execute <<-SQL
           DELETE FROM #{table}
         SQL
       end


       true
     end
  end
 end
