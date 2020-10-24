require "stumpy_png"

module Enumerable(T)
  def mean
    map(&.to_i).sum / size
  end
end

module PNG::Antialias
  VERSION = "0.1.0"

  raise "Missing png file, specify with \"png-antialias <file>\"" unless ARGV[0]?

  canvas = StumpyPNG.read(ARGV[0])
  canvas2 = StumpyPNG.read(ARGV[0])
  width, height = canvas.width - 1, canvas.height - 1
  (0..width).each do |x|
    (0..height).each do |y|
      tangent = [] of Tuple(UInt8, UInt8, UInt8, UInt8)
      (-1..1).each do |xd|
        (-1..1).each do |yd|
          next if x + xd < 0 || x + xd > width
          next if y + yd < 0 || y + yd > height
          tangent << canvas[x+xd, y+yd].to_rgba
        end
      end
      next if tangent.uniq.size == 1
      base = canvas[x, y].to_rgba
      average = tangent.transpose.map(&.mean.to_u8)
      factor = 0.0
      (0..2).each do |e|
        unless average[e] == 0
          sub_factor = base[e] / average[e]
        else
          sub_factor = base[e]
        end
        factor += sub_factor
      end
      factor /= 3
      factor **= 0.03
      (0..2).each do |e|
        average[e] = (average[e].to_i * factor).clamp(0, 255).to_u8
      end
      canvas2[x, y] = StumpyCore::RGBA.from_rgba(average)
    end
  end
  StumpyPNG.write(canvas2, ARGV[0] + ".new")
end
