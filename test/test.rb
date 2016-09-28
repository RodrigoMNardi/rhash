require 'lib/rhash'
require 'rubygems'
require 'test/unit'

class BigBadWolfUnitTest < Test::Unit::TestCase
	def setup
		@rhash = RHash.new
		@hash  = {}
	end
	
	def test_add_value
		assert_nothing_raised do 
			@rhash[:key] = "value"
		end
		
		assert_nothing_raised do 
			@rhash[5] = "value"
		end
		
		assert_nothing_raised do 
			@rhash["555"] = "value"
		end
	end
	
	def test_read_value
		[:a, "5", 5].each do |key|
			@rhash[key] = "value"
			@hash[key] = "value"
			assert_equal @rhash[key], @hash[key]	
		end
	end	
	
	def test_sort
		@rhash[:key] = "5"
		@rhash["cow"] = "moooo..."
		@rhash['4'] = "2*2"
			
		assert_equal ['4', "2*2"],@rhash.sort.first
		assert_equal [:key, "5"],@rhash.sort.last
		
		@rhash.sort!
		
		assert_equal ['4', "2*2"],@rhash.first
		assert_equal [:key, "5"],@rhash.last
	end	
	
	def test_sort_each_sort_each_pair_and_each
		@rhash[:key] = "5"
		@rhash["cow"] = "moooo..."
		@rhash['4'] = "2*2"
				
		count = 0
		@rhash.sort_each do |info|
			case count
			when 0
				assert_equal ['4', "2*2"], info
			when 1
				assert_equal ['cow', "moooo..."], info
			when 2		
				assert_equal [:key, "5"], info
			end
			count += 1	
		end
				
		count = 0
		@rhash.sort_each_pair do |key, value|
			case count
			when 0
				assert_equal ['4', "2*2"], [key, value]
			when 1
				assert_equal ['cow', "moooo..."], [key, value]
			when 2		
				assert_equal [:key, "5"], [key, value]
			end
			count += 1	
		end
				
		count = 0
		@rhash.each do |info|
			case count
			when 2
				assert_equal ['4', "2*2"], info
			when 1
				assert_equal ['cow', "moooo..."], info
			when 0		
				assert_equal [:key, "5"], info
			end
			count += 1	
		end
	end	
	
	def test_select
		@rhash[:key] = "5"
		@rhash["cow"] = "moooo..."
		@rhash['4'] = "2*2"
		
		correct = @rhash.select{|key, value| key == "4"}
		wrong   = @rhash.select{|key| key == "4"}
		
		assert_raise NoMethodError do
			wrong   = @rhash.select{|key| key.key == "4"}
		end
		
		assert wrong.empty?
		assert !correct.empty?
	end
	
	def test_keys_and_values
		@rhash[:key] = 5
		@rhash["cow"] = "moooo..."
		@rhash['4'] = "2*2"
		
		keys = @rhash.keys
		
		assert keys.include?(:key)
		assert keys.include?("cow")
		assert keys.include?("4")
		assert !keys.include?(666)
		
		values = @rhash.values
		
		assert values.include?(5)
		assert values.include?("moooo...")
		assert values.include?("2*2")
		assert !values.include?(55555)
	end
	
	def test_has_key_has_value
		@rhash[:key]  = 5
		@rhash[:key2] = 666 
		
		assert @rhash.has_key?(:key)
		assert !@rhash.has_key?("bfasa")
		assert !@rhash.has_key?(1654654)
		assert !@rhash.has_key?(:dhsafduafdas)
		assert @rhash.has_key?(:key2)
		
		assert @rhash.has_value?(5)
		assert !@rhash.has_value?("bfasa")
		assert !@rhash.has_value?(1654654)
		assert !@rhash.has_value?(:dhsafduafdas)
		assert @rhash.has_value?(666)	
	end
	
	def test_delete_if
		@rhash[:key] = 5
		
		@rhash.delete_if{|k| k == :key}
		assert !@rhash.empty?
		
		assert_raise NoMethodError do
			@rhash.delete_if{|k| k.key == :key}
		end
		
		@rhash.delete_if{|k,v| k == :key}
		assert @rhash.empty?
		
		@rhash[:key] = 5
		@rhash[:key2] = 5
		@rhash.delete_if
		assert !@rhash.empty?
		
		@rhash.delete_if{|k,v| k == :key}
		assert !@rhash[:key]
		assert @rhash[:key2]
	end
	
	def test_delete
		@rhash[:key] = 5
		
		@rhash.delete(:key)
		assert @rhash.empty?	
		
		assert !@rhash.delete(:key){"Boooom!"}	
	end
	
	def test_size
		@rhash[:key]  = 5
		@rhash[:key1] = 55
		@rhash[:key2] = 555
		@rhash[:key3] = 5555
		@rhash[:key4] = 55555
		
		assert_equal 5, @rhash.size
	end	
	
	def test_invert
		# Easy invert
		@rhash[:key]  = 5
		inverted_rhash = @rhash.invert
		
		assert_equal :key, inverted_rhash[5] 
		
		@rhash[:key1]  = 6
		@rhash[:key2]  = 7
		@rhash[:key3]  = 8
		
		inverted_rhash = @rhash.invert
		
		assert_equal :key1, inverted_rhash[6]
		assert_equal :key2, inverted_rhash[7]
		assert_equal :key3, inverted_rhash[8]
	end	
	
	def test_merge
		@rhash[:key]  = 5
		@rhash[:key1] = 55
		
		@hash[:key2] = 6
		@hash[:key3] = 66
		
		assert_nothing_raised do 
			@rhash.merge @hash
		end
		
		merged_rhash = @rhash.merge @hash
		
		assert_equal 5, merged_rhash[:key]
		assert_equal 55, merged_rhash[:key1]
		assert_equal 6, merged_rhash[:key2]
		assert_equal 66, merged_rhash[:key3]
		
		@rhash.merge! @hash
		
		assert_equal 5, @rhash[:key]
		assert_equal 55, @rhash[:key1]
		assert_equal 6, @rhash[:key2]
		assert_equal 66, @rhash[:key3]
		
		@hash[:key] = 6
		
		@rhash.merge! @hash
		
		# HAHAHAHA
		# Merge with same key.		
		assert_equal 6, @rhash[:key]
		assert_equal 55, @rhash[:key1]
		assert_equal 6, @rhash[:key2]
		assert_equal 66, @rhash[:key3]
	end
	
	def test_fat_fetch
		@rhash[:key]  = 5
		@rhash[:key1] = 55
		
		assert_equal 5, @rhash.fetch(:key)
		
		assert_raise IndexError do 
			@rhash.fetch(:key666)
		end
	end	
	
	def teardown
		@rhash.clear
	end	
	
end
