class Symbol
  def <=>(other)
    self.to_s <=> other.to_s
  end
end

class Info
	attr_accessor :key
	attr_accessor :value
	
	def to_s
		"#{key.inspect} => #{value.inspect}"
	end
end

class RHash
	#
	# Returns a new, empty RHash.
	# If a block is specified, it will be called with the RHash object and the key, 
	# and should return the default value. It is the block‘s responsibility to 
	# store the value in the RHash if required.
	#
	def initialize(&block)
		@hash = []
		@default = nil
		@default = block if block_given?
	end
	
	#
	# Returns value corresponding to key. 
	# If the key wasn't found, an IndexError exception will be raised.
	#
	#  my_hash = RHash.new
	#
	#  my_hash["cow"] = "mooo..." 
	#
	#  my_hash["cow"]               #=> "mooo..."
	#
	#  my_hash["chick"]             #=> nil
	#
	def [] key
		@hash.each do |info|
			return info.value if key == info.key
		end
		(@default.is_a? Proc)? @default.call : @default  
	end	
	
	#
	# Associates the value given by value with the key given by key.
	# If already exists a key then key value will be updated.
	#
	#  my_hash = RHash.new
	#
	#  my_hash["cow"] = "mooo..."
	#
	#  my_hash["cow"]               #=> "mooo..."
	#
	#  my_hash["cow"] = "cocó..."
	#
	#  my_hash["cow"]               #=> "cocó..."
	#
	def []= key, value
		info = Info.new
		info.key = key
		info.value = value
		
		if new_hash_entry? info
			@hash << info
		else
			update_key	info
		end
	end	
	
	#
	# Returns a RHash orderned by key name or block.
	# If block is given using Array#sort else sort by name.
	#
	#  my_hash = RHash.new
	#  
	#  my_hash["cow"] = "mooo..."
	#
	#  my_hash["chick"] = "cocó..." 
	#
	#  my_hash["bee"] = "ziiii..."
	#
	#  my_hash.sort                #=> Returns RHash object.
	#
	#  sort_hash = my_hash.sort
	#
	#  sort_hash.inspect           #=> {"bee" => "ziiii...", "chick" => "cocó...", "cow" => "mooo..."}
	#
	def sort(&block)
		sort_rhash = RHash.new
		int_sort(&block).each do |info|
			sort_rhash[info.key] = info.value
		end
		sort_rhash
	end
	
	#
	# Sorts self.
	# If block is given using Array#sort else sort by name.
	#
	#  my_hash = RHash.new
	#  
	#  my_hash["cow"] = "mooo..."
	#
	#  my_hash["chick"] = "cocó..." 
	#
	#  my_hash["bee"] = "ziiii..."
	#
	#  my_hash.sort!.inspect       #=> {"bee" => "ziiii...", "chick" => "cocó...", "cow" => "mooo..."}
	#
	def sort!(&block)
		sort_hash = int_sort(&block)
		clear
		sort_hash.each do |info|
			self[info.key] = info.value
		end
	end	
	
	#
	# Orders RHash and calls block once for each key in RHash,
	# passing the key and value to the block as a two-element array
	#
	def sort_each(&block)
		new_hash = int_sort
		new_hash.each do |info|
			yield [info.key, info.value] if block_given?
		end
	end
	
	#
	# Orders RHash and calls block once for each key in RHash,
	# passing the key and value to the block.
	#
	def sort_each_pair(&block)
		new_hash = int_sort
		new_hash.each do |info|
			yield info.key, info.value if block_given?
		end
	end
	
	#
	# See Hash::each
	#
	def each(&block)
		@hash.each do |info|
			yield [info.key, info.value] if block_given?
		end
	end
	
	#
	# See Hash::each_pair
	#
	def each_pair(&block)
		@hash.each do |info|
			yield info.key, info.value if block_given?
		end
	end	
	
	#
	# See Hash::each_value
	#
	def each_value(&block)
		array(:value).each do |value|
			yield value if block_given?
		end	
	end	
	
	#
	# See Hash::each_key
	#
	def each_key(&block)
		array(:key).each do |value|
			yield value if block_given?
		end	
	end	
	
	#
	# See Hash::select
	#		
	def select(&block)
		selected_entries = []
		@hash.each do |info|
			if block_given?
				if yield info.key, info.value
					selected_entries << [info.key, info.value]
				end
			end
		end
		selected_entries
	end	
	
	#
	# See Hash::keys
	#
	def keys
		new_array = []
		@hash.each{|info| new_array << info.key}
		new_array
	end	
	
	#
	# See Hash::values
	#
	def values	
		new_array = []
		@hash.each{|info| new_array << info.value}
		new_array
	end	
	
	#
	# See Hash::key?
	#
	def has_key?(key)
		@hash.each{|info| return true if info.key == key}
		false
	end
	alias :key? :has_key?
	alias :member? :has_key?
	
	#
	# See Hash::value?
	#
	def has_value?(value)
		@hash.each{|info| return true if info.value == value}
		false
	end		
	alias :value? :has_value?
	
	#
	# See Hash::delete_if
	#
	def delete_if(&block)
		@hash.delete_if{|info| yield info.key, info.value if block_given?}
	end
	
	#
	# See Hash::delete
	#
	def delete(key, &block)
		deleted = nil
		@hash.delete_if{|info| info.key == key; deleted = info if info.key == key}
		yield key.inspect if block_given? and !deleted
		return "Deleted: #{deleted.key.inspect} => #{deleted.value.inspect}" if deleted
	end
	
	#
	# See Hash::size
	#
	def size
		@hash.size
	end
	
	alias :length :size
		
	#
	# See Hash::invert
	#	
	def invert
		new_hash = RHash.new
		@hash.each do |i|
			new_hash[i.value] = i.key
		end
		new_hash
	end

	#
	# See Hash::merge
	#	
	def merge(rhash)
		new_hash = RHash.new
		raise "Não é uma Hash ou RHash" unless rhash.is_a? RHash or rhash.is_a? Hash
		
		# Problema com o clone/dup Object.
		@hash.each do |i|
			new_hash[i.key] = i.value
		end
		
		if rhash.is_a? RHash
			rhash.each do |info|
				new_hash[info.key] = info.value
			end
		else
			rhash.each_pair do |key, value|
				new_hash[key] = value
			end	
		end
		
		new_hash
	end	
	
	#
	# See Hash::merge!
	#	
	def merge!(rhash)
		raise "Não é uma Hash ou RHash" unless rhash.is_a? RHash or rhash.is_a? Hash
		if rhash.is_a? RHash
			rhash.each do |info|
				self[info.key] = info.value
			end
		else
			rhash.each_pair do |key, value|
				self[key] = value
			end	
		end
	end
	
	#
	# See Hash::store
	#
	def store(key, value)
		self[key] = value
	end	
	
	#
	# Returns an array with first key and value found in RHash. 
	#
	def first
		first = @hash.first
		[first.key, first.value]
	end
	
	#
	# Returns an array with last key and value found in RHash. 
	#
	def last 
		last = @hash.last
		[last.key, last.value]
	end
	
	#
	# See Hash::fetch
	#
	def fetch(key, msg='', &block)
		value = select{|k, v| k == key}[0]
				
		if block_given?
			yield
		else
			if value.nil?							
				raise IndexError, "Key (#{key.inspect}): not found" if msg.empty?
			end
		end	
		
		value[1]
	end
	
	#
	# See Hash::clear
	#
	def clear
		@hash = []
	end
	
	#
	# See Hash::default=
	#
	def default=(value)
		@default = value
	end	
	
	#
	# See Hash::default
	#
	def default(key)		
		if @default.is_a? Proc
			info = Info.new
			info.key = key
			info.value = @default.call(self, key)
			self[info.key] = info.value
		else
			info = Info.new
			info.key = key
			info.value = @default
			self[info.key] = info.value	
		end
	end	
	
	#
	# See Hash::shift
	#
	def shift
		shifted = @hash.shift
		[shifted.key, shifted.value]
	end		
	
	#
	# See Hash::empty?
	#
	def empty?
		@hash.empty?
	end	
	
	#
	# See Hash::values_at
	#
	def values_at(*keys)
		selected = []
		@hash.each do |info|
			selected << info.value if keys.include? info.key
		end
		selected
	end
	
	#
	# See Hash::==
	# 
	def ==(other)
		if other.is_a? Hash
			return equal(other)
		end
		
		if other.is_a? RHash
			return equal(other)
		end	
		false
	end
	
	#
	# Returns two arrays with difference between RHash and Hash/RHash.
	# Each array contains different keys and values have found. 
	# The first array is related to whom calls the method 
	# and the second array referring to those who want to diff.
	#
	#  n = RHash.new
	#
	#  n["r"] = 5
	#
	#  n["s"] = 6
	#
	#  n["d"] = 5
	#
	#  n[:h] = "ola"
	#
	#  n[:m] = 5
	#
	#  x= RHash.new
	#
	#  x["r"] = 5
	#
	#  x["s"] = 6
	#
	#  x["d"] = 5
	#
	#  x["t"] = 5
	#
	#  n.diff x        #=> [[:h, "ola"], [:m, 5]], [["t", 5]]
	#
	def diff(other)
		if other.is_a? Hash
			return int_diff(other)
		end
		
		if other.is_a? RHash
			return int_diff(other)
		end	
	end	
	
	#
	# Converts the RHash to a XML.
	#
	#  x= RHash.new
	#
	#  x["code"] = RHash.new
	#
	#  x["code"]["color"] = "0x0454"
	#
	#  x["code"]["size"] = 24
	#
	#  x["code"]["letter"] = "Arial"
	#
	#  x["code"]["mode"] = RHash.new
	#
	#  x["code"]["mode"]["present"] = "Love"
	#
	#  x["code"]["mode"]["to"] = "Rose Mary"
	#
	#  x.to_xml            #=> <code>
	#
	#                          <color>0x0454</color>
	#
	#                          <size>24</size>
	#
	#                          <letter>Arial</letter>
	#
	#                          <mode>
	#
	#                          <present>Love</present>
	#
	#                          <to>Rose Mary</to>
	#
	#                          </mode>
	#
	#                          </code>
	#
	def to_xml
		msg_xml = ''
		@hash.each do |info|
			msg_xml += "<#{info.key}>#{xml(info.value)}</#{info.key}>\n"
		end
		msg_xml
	end	
	alias :to_html :to_xml
	
	def to_yaml
		yamlfy()
	end	
	
	#
	# See Hash::to_a
	#
	def to_a
		array = []
		@hash.each do |info|
			array << [info.key, info.value]
		end
		array
	end	
	
	#
	# Return the contents of this hash as a string.
	#
	def inspect		
		msg = '{'
		@hash.each_with_index do |info, index|
			msg += info.to_s
			msg += ", " if @hash.size > 1 and index + 1 < @hash.size 
		end
		msg += '}'
		msg
	end

	#
	# See RHash::inspect
	#	
	def to_s
		inspect
	end	
	
	#
	# Converts to a Hash.
	#
	def to_hash
		pure_hash = {}
		@hash.each do |info|
			pure_hash[info.key] = info.value
		end
		pure_hash
	end	
	
	private
	
	def yamlfy
		yaml = ''
		whitespace = "  "
		self.each_pair do |key, value|
			if value.is_a? Hash or value.is_a? RHash
				yaml += "#{key}:\n"
				value.each_pair do |sub_key, sub_value| 
					if sub_value.is_a? RHash
						yaml += whitespace + "#{sub_key}: \n"
						subwhitespace = whitespace + "  "
						yaml += recursive_yaml(sub_value, subwhitespace)
					else
						if sub_value.is_a? Hash		
							yaml += whitespace + "#{sub_key}: \n"
							subwhitespace = whitespace + "  "					
							yaml += recursive_yaml(sub_value, subwhitespace)
						else	
							yaml += whitespace+"#{sub_key}: #{sub_value}\n"
						end
					end		
				end		
			else
				yaml += "#{key}: #{value}\n"
			end		
		end
		yaml
	end
	
	def recursive_yaml(info,whitespace='')	
		info_str = ''
		info.each_pair do |key, value|
			if value.is_a? Hash or value.is_a? RHash
				info_str += whitespace + "#{key}:\n"
				whitespace = whitespace + "  "
				info_str += recursive_yaml(value, whitespace)				
			else
				info_str += whitespace + "#{key}: #{value}\n"
			end	
		end			
		info_str
	end
	
	def xml(info)
		msg_xml = ""
		if info.is_a? RHash
			msg_xml += "\n"
			info.each do |subinfo|
				msg_xml += "<#{subinfo[0]}>#{xml(subinfo[1])}</#{subinfo[0]}>\n"
			end
		else
			msg_xml += "#{info}"
		end
		msg_xml
	end	
	
	def equal(other)
		if other.size == self.size
			hits = other.size
			self.each_pair do |key, value|
				other.each_pair do |k,v|
					hits = hits - 1 if (key == k) and (value == v)						
				end					
			end
			return (hits == 0)? true : false
		else
			return false	
		end
	end
	
	def int_diff(other)
		my_diff    = []
		other_diff = []
		is_member  = false
		self.each_pair do |key, value|
			other.each_pair do |k,v|
				is_member = true if (key == k) and (value == v)						
			end
			my_diff << [key, value] unless is_member
			is_member = false		
		end
		
		is_member  = false
		other.each_pair do |key, value|
			self.each_pair do |k,v|
				is_member = true if (key == k) and (value == v)						
			end
			other_diff << [key, value] unless is_member
			is_member = false		
		end
		
		return my_diff, other_diff
	end
	
	def int_sort(&block)
		new_hash = []
		if !block_given?
			new_hash = @hash.sort_by{|info| info.key}
		else
			aux = []
			@hash.each do |info|
				aux << [info.key, info.value]
			end
			new_hash = aux.sort(&block)
		end		
		new_hash
	end
	
	def array(mode)
		array = []
		@hash.each do |info|
			array << info.__send__(mode.to_sym)
		end
		array
	end	
	
	def new_hash_entry? info
		@hash.each do |e|
			return false if e.key == info.key
		end
		true
	end
	
	def update_key info
		@hash.each do |e|
			if e.key == info.key
				e.value = info.value
			end	
		end
	end	
end



