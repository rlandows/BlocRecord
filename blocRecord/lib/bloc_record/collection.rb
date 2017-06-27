module BlocRecord
   class Collection < Array
     def update_all(updates)
       ids = self.map(&:id)
       self.any? ? self.first.class.update(ids, updates) : false
     end

     def take(*args)
       ids = self.map(&:id)
       self.any? ? self.first.class.take(*args) : false
     end

     def where(*args)
      #  puts args
       ids = self.map(&:id)
       self.any? ? self.first.class.where(*args) : false
     end

     def not(*args)
       ids = self.map(&:id)
       self.any? ? self.first.class.not(*args) : false
     end
   end
 end
