require 'rubygems'
require 'rmagick'
include Magick

class Array
  def odd_values
    self.values_at(* self.each_index.select {|i| i.odd?})
  end
  def even_values
    self.values_at(* self.each_index.select {|i| i.even?})
  end
end

#For each file (NOT WRITTEN YET)
original_dir = Dir.pwd
Dir.mkdir("temp")
Dir.mkdir("booklets") unless File.exists?("booklets")

#split into individual pdfs in
`pdftk #{ARGV[0]} burst output temp/page_%02d.pdf`

Dir.chdir("temp")

#Set variables for: total number of files (pages), filename
pages = Dir["*.pdf"]
pages.each do |page|
  pagenum = page.to_s.scan(/\d+/)
  pdf = ImageList.new("#{page}") { 
    self.density = "30"}
    width = pdf[0].columns
    height = pdf[0].rows
  
  #crop and output as jpgs then pdfs for 1st page  
  pageone = pdf.crop(0, 0, width/2, height)
  pageone.write("page_#{pagenum}A.jpg")
  jpg = ImageList.new("page_#{pagenum}A.jpg")
  jpg.write("page_#{pagenum}A.pdf")
  
  #crop and output as jpgs then pdfs for 2nd page
  pagetwo = pdf.crop(width/2, 0, width/2, height)
  pagetwo.write("page_#{pagenum}B.jpg")
  jpg = ImageList.new("page_#{pagenum}B.jpg")
  jpg.write("page_#{pagenum}B.pdf")
  
end

a_pages = Dir["*A.pdf"]
b_pages = Dir["*B.pdf"]

a_pages_odd = a_pages.odd_values
a_pages_even = a_pages.even_values.reverse
b_pages_odd = b_pages.odd_values.reverse
b_pages_even = b_pages.even_values

combined_pages = b_pages_even.zip(a_pages_odd).flatten + b_pages_odd.zip(a_pages_even).flatten

#combine all pdfs to single pdf with original name in folder /booklets
`pdftk #{combined_pages.join(' ')} output #{File.join(File::SEPARATOR , original_dir, 'booklets', ARGV[0])}`

#delete contents of /temp
Dir["*"].each {|f| File.delete(f) }
Dir.chdir(original_dir)
Dir.delete("temp")
