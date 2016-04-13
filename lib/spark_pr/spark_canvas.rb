# pure ruby sparklines module, generates PNG or ASCII
# contact thomas@fesch.at for questions
#
# strives to be somewhat compatible with sparklines lib by
# {Dan Nugent}[mailto:nugend@gmail.com] and {Geoffrey Grosenbach}[mailto:boss@topfunky.com]
#
# png creation based on http://www.whytheluckystiff.net/bumpspark/

require 'zlib'

class SparkCanvas

  attr_accessor :color
  attr_reader :width, :height

  def initialize(width,height,base_color=[0xFF,0xFF,0xFF])
    @canvas = []
    @height = height
    @width = width
    height.times{ @canvas << [base_color]*width }
    @color = [0,0,0,0xFF] #RGBA
  end

  # alpha blends two colors, using the alpha given by c2
  def blend(c1, c2)
    (0..2).map{ |i| (c1[i]*(0xFF-c2[3]) + c2[i]*c2[3]) >> 8 }
  end

  # calculate a new alpha given a 0-0xFF intensity
  def intensity(c,i)
    [c[0],c[1],c[2],(c[3]*i) >> 8]
  end

  # calculate perceptive grayscale value
  def grayscale(c)
    (c[0]*0.3 + c[1]*0.59 + c[2]*0.11).to_i
  end

  def point(x,y,color = nil)
    return if x<0 or y<0 or x>@width-1 or y>@height-1
    @canvas[y][x] = blend(@canvas[y][x], color || @color)
  end

  def rectangle(x0, y0, x1, y1)
    x0, y0, x1, y1 = x0.to_i, y0.to_i, x1.to_i, y1.to_i
    x0, x1 = x1, x0 if x0 > x1
    y0, y1 = y1, y0 if y0 > y1
    x0.upto(x1) { |x| y0.upto(y1) { |y| point x, y } }
  end

  # draw an antialiased line
  # google for "wu antialiasing"
  def line(x0, y0, x1, y1)
    # clean params
    x0, y0, x1, y1 = x0.to_i, y0.to_i, x1.to_i, y1.to_i
    y0, y1, x0, x1 = y1, y0, x1, x0 if y0>y1
    sx = (dx = x1-x0) < 0 ? -1 : 1 ; dx *= sx ; dy = y1-y0

    # special cases
    x0.step(x1,sx) { |x| point x, y0 } and return if dy.zero?
    y0.upto(y1)    { |y| point x0, y } and return if dx.zero?
    x0.step(x1,sx) { |x| point x, y0; y0 += 1 } and return if dx==dy

    # main loops
    point x0, y0

    e_acc = 0
    if dy > dx
      e = (dx << 16) / dy
      y0.upto(y1-1) do
        e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xFFFF
        x0 += sx if (e_acc <= e_acc_temp)
        point x0, (y0 += 1), intensity(@color,(w=0xFF-(e_acc >> 8)))
        point x0+sx, y0, intensity(@color,(0xFF-w))
      end
      point x1, y1
      return
    end

    e = (dy << 16) / dx
    x0.step(x1-sx,sx) do
      e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xFFFF
      y0 += 1 if (e_acc <= e_acc_temp)
      point (x0 += sx), y0, intensity(@color,(w=0xFF-(e_acc >> 8)))
      point x0, y0+1, intensity(@color,(0xFF-w))
    end
    point x1, y1
  end

  def polyline(arr)
    (0...arr.size-1).each{ |i| line(arr[i][0], arr[i][1], arr[i+1][0], arr[i+1][1]) }
  end

  def to_png
    header = [137, 80, 78, 71, 13, 10, 26, 10].pack("C*")
    raw_data = @canvas.map { |row| [0] + row }.flatten.pack("C*")
    ihdr_data = [@canvas.first.length,@canvas.length,8,2,0,0,0].pack("NNCCCCC")

    header +
      build_png_chunk("IHDR", ihdr_data) +
      build_png_chunk("tRNS", ([ 0xFF ]*6).pack("C6")) +
      build_png_chunk("IDAT", Zlib::Deflate.deflate(raw_data)) +
      build_png_chunk("IEND", "")
  end

  def build_png_chunk(type,data)
    to_check = type + data
    [data.length].pack("N") + to_check + [Zlib.crc32(to_check)].pack("N")
  end

  def to_ascii
    chr = %w(M O # + ; - .) << ' '
    @canvas.map{ |r| r.map { |pt| chr[grayscale(pt) >> 5] }.join << "\n" }.join
  end
end
