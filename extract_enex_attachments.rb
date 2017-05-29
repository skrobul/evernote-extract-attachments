#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

# http://blog.evernote.com/tech/2013/08/08/evernote-export-format-enex/

require 'nokogiri'
require 'date'
require 'ostruct'
require 'fileutils'
require 'base64'
require 'digest'

class Note < OpenStruct; end
class Notes < Array; end


def extension(mime)
  case mime
  when 'application/pdf' then 'pdf'
  when 'image/jpeg' then 'jpg'
  when 'image/png' then 'png'
  when 'image/gif' then 'gif'
  when 'image/bmp' then 'bmp'
  when 'application/octet-stream' then 'data'
  else raise "Unknown mime type: #{mime}"
  end
end

def sanitize(dirty_name)
  return unless dirty_name
  dirty_name.gsub(/\/+/, '')
end

def guess_name(res, mime_type)
   digest = Digest::MD5.hexdigest(res.xpath('data').first.content) 
   extension = extension(mime_type)
   "#{digest}.#{extension}"
end

notes = Notes.new

xml = Nokogiri::XML(File.read(ARGV[0]))
xml.xpath("//note").each do |n|
  note = Note.new
  note.title = n.xpath('title').first.content
  # note.content_xml = n.xpath('content').first.content
  # note.content = Nokogiri::XML(note.content_xml).content
  #
  # note.created = DateTime.parse(n.xpath('created').first.content)
  # note.updated = DateTime.parse(n.xpath('updated').first.content)
  # note.tags = n.xpath('tag').map(&:content)
  # note.attributes = n.xpath('note-attributes')
  #                    .children
  #                    .inject({}){|h, i| h[i.name] = i.content ; h }
  note.attachments = []
  puts "# #{note.title}"
  n.xpath('resource').each do |res|
    att_type = res.xpath('mime').first
    next unless att_type
    filename = sanitize(res.xpath('resource-attributes//file-name').first&.content)
    filename ||= guess_name(res, att_type.content)
    encoded_res_content = res.at_xpath('data')&.content
    next unless encoded_res_content
    outpath = "output/#{note.title}"
    FileUtils.mkdir_p outpath
    puts "Found #{att_type.content} : #{filename}"
    File.write(File.join(outpath, filename), Base64.decode64(encoded_res_content))
    recognized_text = res.xpath('recognition').first&.content
    if recognized_text
      File.write(File.join(outpath, "recognition_#{filename}.xml"), recognized_text)
    end
  end
#  notes << note
end
#puts notes
