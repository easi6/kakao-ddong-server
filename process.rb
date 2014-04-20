#!/usr/bin/env ruby

require "rmagick"

patch_70 = Magick::Image.read("assets/patch_20.png")[0]
img = Magick::Image.read(ARGV[0])[0]
#img = img.edge(3)
#img.colorspace = Magick::GRAYColorspace

#draw = Magick::Draw.new
#draw.fill = "transparent"
#draw.circle(35, 35, 4, 35)

mode = 0
y_start = 0
y_end = 0
ys = []
prev = 0
(130..1040).each do |y|
  #px = img.get_pixels(10, y, 1, 2);
  #px = img.get_pixels(ARGV[1].to_i, ARGV[2].to_i, 1, 2);
  #puts px[0].to_color
  #puts px[1].to_color
  #puts
  #part = img.export_pixels(ARGV[1].to_i, ARGV[2].to_i, 70, 70)
  part = img.export_pixels(8, y, 70, 20)
  part_img = Magick::Image.constitute(70, 20, "RGB", part)

  #draw.draw(part_img)
  #part_img.write("asdf.png")

  diff = part_img.difference(patch_70)[0]

  if prev == 0 && diff >= 10
    y_start = y + 20
  end

  if prev != 0 && diff < 10
    ys << [y_start, y]
  end
  #if diff >= 20 && mode == 0
    ##region start
    #y_start = y + 70
    #mode = 1
    #next
  #end

  #if diff < 20 &&  mode == 1
    #y_end = y
    #ys << [y_start, y_end]
    #mode = 0
  #end


  prev = diff
  #puts "y = #{y}, #{part_img.difference(patch_70)[0]}"
end

puts ys.map {|xx| xx.join(", ")}
