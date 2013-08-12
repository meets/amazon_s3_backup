require 'bigdecimal'

class FilesizeUnitConvert

	def self.int2str(length)

    units = ['', 'K', 'M', 'G']
    unit = ''
    4.times do
      unit = units.shift
      if length < 1024
        break;
      end

      length = length / 1024.0
    end

    length = BigDecimal::new(length.to_s).ceil(2).to_f

    "#{length} #{unit}B"
	end

end