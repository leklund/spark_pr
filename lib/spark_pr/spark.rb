require 'base64'
require_relative 'spark_canvas'

class Spark
  attr_accessor :opts, :png, :canvas

  def initialize(options)
    # process options
    o = options.inject({}) do |o, (key, value)|
      o[key.to_sym] = value ; o
    end
    [:height, :width, :step].each do |k|
      o[k] = o[k].to_i if o.has_key?(k)
    end
    [:has_min, :has_max, :has_last].each do |k|
      o[k] = (o[k] ? true : false) if o.has_key?(k)
    end
    o[:normalize] ||= :linear
    o[:normalize] = o[:normalize].to_sym

    self.opts = o
  end

  # normalize arr to contain values between 0..1 inclusive
  def normalize( arr, type = :linear )
    arr = arr.map { |v| v.to_f == 0.0 ? 0.0 : Math.log(v) } if type == :logarithmic

    return arr if arr.min == arr.max

    adj, fac = arr.min, arr.max-arr.min
    arr.map {|v| (v-adj).quo(fac) rescue 0 }
  end

  def smooth( results )
    o = {
      :step => 2,
      :height => 14,
      :has_min => false,
      :has_max => false
    }.merge(opts)

    o[:width] ||= (results.size-1)*o[:step] + 5

    c = if o[:base_color]
          SparkCanvas.new(o[:width], o[:height], o[:base_color])
        else
          SparkCanvas.new(o[:width], o[:height])
        end


    results = normalize(results, o[:normalize])
    fac = c.height-5
    i = -o[:step]
    coords = results.map do |r|
      [(i += o[:step])+2, c.height - 3 - r*fac ]
    end

    c.color = opts[:line_color] || [0xB0, 0xB0, 0xB0, 0xFF]
    c.polyline coords

    if o[:has_min]
      min_pt = coords[results.index(results.min)]
      c.color = [0x80, 0x80, 0x00, 0x70]
      c.rectangle(min_pt[0]-2, min_pt[1]-2, min_pt[0]+2, min_pt[1]+2)
    end

    if o[:has_max]
      max_pt = coords[results.index(results.max)]
      c.color = [0x00, 0x80, 0x00, 0x70]
      c.rectangle(max_pt[0]-2, max_pt[1]-2, max_pt[0]+2, max_pt[1]+2)
    end

    if o[:has_last]
      c.color = [0xFF, 0x00, 0x00, 0x70]
      c.rectangle(coords.last[0]-2, coords.last[1]-2, coords.last[0]+2, coords.last[1]+2)
    end
    self.png = c.to_png
    self.canvas = c
  end

  def discrete( results )
    o = {
      :height => 14,
      :upper => 0.5,
      :has_min => false,
      :has_max => false
    }.merge(opts)

    o[:width] ||= results.size*2-1

    c = if o[:base_color]
          SparkCanvas.new(o[:width], o[:height], o[:base_color])
        else
          SparkCanvas.new(o[:width], o[:height])
        end

    results = normalize(results, o[:normalize])
    fac = c.height-4

    i = -2
    results.each do |r|
      p = c.height - 4 - r*fac
      c.color = r < o[:upper] ? [0x66,0x66,0x66,0xFF] : [0xFF,0x00,0x00,0xFF]
      c.line(i+=2, p, i, p+3)
    end

    self.png = c.to_png
    self.canvas = c
  end

  def data_uri
    %{data:image/png;base64,#{Base64.encode64(png).gsub("\n",'')}}
  end

  # convenience methods
  def self.plot( results, options = {} )
    spark = Spark.new(options)
    type = spark.opts.delete(:type) || :smooth
    spark.send(type, results).to_png
  end

  def self.data_uri( results, options = {} )
    spark = Spark.new(options)
    type = spark.opts.delete(:type) || :smooth
    spark.send(type, results)
    spark.data_uri
  end
end

