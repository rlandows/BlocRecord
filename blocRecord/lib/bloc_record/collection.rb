
module BlocRecord
   class Collection < Array
     def update_all(updates)
       ids = self.map(&:id)
       self.any? ? self.first.class.update(ids, updates) : false
     end

     def take(num = 1)
       ids = self.map(&:id)
       id_list = ids[0..num - 1]
       self.any? ? self.first.class.find(*id_list) : false
     end

     def where(*args)
       ids = self.map(&:id)
       id_string = ids.join(",")
       args[0][:id] = id_string
       self.any? ? self.first.class.where(*args) : false
     end

     def not(*args)
       ids = self.map(&:id)
       self.any? ? self.first.class.not("id IN (#{ids.join(",")})") : false
     end

     def destroy_all(*args)
       ids = self.map(&:id)
         self.first.class.destroy(*ids)
     end
   end
 end
