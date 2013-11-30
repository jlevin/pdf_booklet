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

#Burst pdf into single pages, split pages, and reorder into single pdf
def make_booklet(inputpdf)
original_dir = Dir.pwd
Dir.mkdir("temp")
Dir.mkdir("booklets") unless File.exists?("booklets")

#split into individual pdfs
`pdftk '#{inputpdf}' burst output temp/page_%02d.pdf`

Dir.chdir("temp")

#Create array of individual pdfs
pages = Dir["*.pdf"]
pages.each do |page|
  pagenum = page.to_s.scan(/\d+/)
  pdf = ImageList.new("#{page}") { 
    self.density = "300"}
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
`pdftk #{combined_pages.join(' ')} output '#{File.join(File::SEPARATOR , original_dir, 'booklets', inputpdf)}'`

#delete contents of /temp
Dir["*"].each {|f| File.delete(f) }
Dir.chdir(original_dir)
Dir.delete("temp")
end

#For each input pdf
ARGV.each do |input|
  make_booklet(input)
end