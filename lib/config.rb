require 'json'

module BSR
	class Config

		def initialize(filename)
			@settings = JSON.parse File.open(filename).read
		end

		def method_missing(sym, *args, &block)
	    @settings[sym.to_s]
	  end

	end
end