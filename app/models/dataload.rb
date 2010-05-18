class MyTempfile < Tempfile
  attr_accessor :original_filename
end

class UrlFile
  attr_accessor :url
  include FromHash
  def basename
    url.split("/").last
  end
  def tempfile
    require 'open-uri'
    mylog "tempfile", :url => url, :last => basename
    res = MyTempfile.new(basename)
    res.original_filename = basename
    res << (open(url) { |f| f.read })
    res
  end
  def self.file(url)
    new(:url => url).tempfile
  end
end

class ReadProxy
  attr_accessor :file
  include FromHash
  def method_missing(sym,*args,&b)
    file.send(sym,*args,&b)
  end
  fattr(:read) { file.read }
  def respond_to?(x)
    file.respond_to?(x)
  end
end

require 'mongo_mapper'
require 'joint'

class Dataload
  include MongoMapper::Document
  plugin Joint
  attachment :file
  key :coll_name
  key :url
  key :data
  key :ignore_duplicates, Boolean
  belongs_to :workspace
  before_create 'set_file_from_url!'
  def text
    file.name.present? ? wrapped_file.read : nil
  end
  def set_file_from_url!
    if url.present?
      self.file = UrlFile.file(url) 
    elsif data.present?
      self.file = data_tempfile
    end
  end
  def data_tempfile
    f = Tempfile.new('gdfgfhfghfg.sql')
    f << data
    f
  end
  def myfilename
    file.name
  end
end

class Dataload
  key :rows_added
  fattr(:wrapped_file) { ReadProxy.new(:file => file) }
  def duplicate?(c,row)
    res = c.find_one(row)
    mylog "duplicate", :res => res
    !!res
  end
  def should_ignore?(c,row)
    ignore_duplicates && duplicate?(c,row)
  end
  def run!
    self.rows_added ||= 0
    ImportEverything.each_table_and_rows(:file => wrapped_file) do |table,rows|
      c = workspace.get_or_create_coll(table.to_s)
      rows.each do |row| 
        unless should_ignore?(c,row) 
          c.save(row) 
          self.rows_added += 1
        end
      end
      c.invalidate_cache!
    end
    save!
  end
  fattr(:preview) { ImportEverything.preview(import_ops) }
  def import_ops
    {:file => wrapped_file}.merge(addl_ops)
  end
end

class Dataload
  key :addl_ops, Hash
  def addl_ops_hash
    res = addl_ops.clone
    preview.addl_required_fields.each { |x| res[x.to_s] ||= '' }
    mylog "dataload", :addl_ops => addl_ops, :res => res
    res
  end
  def method_missing(sym,*args,&b)
    if sym.to_s[-1..-1] == '='
      self.addl_ops[sym.to_s[0..-2]] = args.first
    else
      super
    end
  end
end

class Dataload
  def self.find(*args)
    if args.first == :all
      all(*args[1..-1])
    else
      super
    end
  end
end

# class Dataload
#   attr_accessor :coll, :data, :url, :file, :workspace, :actual
#   include FromHash
#   fattr(:addl_ops) { {} }
#   def import_ops
#     {:file => get_file}.merge(addl_ops)
#   end
#   def save!
#     ImportEverything.each_table_and_rows(:file => get_file) do |table,rows|
#       c = workspace.get_or_create_coll(table.to_s)
#       rows.each { |row| c.save(row) }
#       c.invalidate_cache!
#     end
#   end
#   fattr(:get_file) do
#     if url.present?
#       require 'open-uri'
#       MockFile.new(:filename => url, :read => open(url, 'rb') { |f| f.read })
#     elsif file.present?
#       file
#     else
#       data
#     end
#   end
#   fattr(:preview) { ImportEverything.preview(import_ops) }
#   def to_json
#     #save! if preview.ready?
#     mylog "dataload", :ready => preview.ready?, :actual => actual
#     if preview.ready?
#       if actual
#         save!
#         {:ran => true}
#       else
#         mylog 'dataload', :stuff => 'ready not actual'
#         res = {:addl_required_fields => preview.addl_required_fields, :result => true, :tables => preview.tables.map { |x| x.to_hash }}
#         mylog 'dataload', :stuff => 'ready not actual 2'
#         res
#       end
#     else
#       {:addl_required_fields => preview.addl_required_fields, :result => false}
#     end
#   end
#   def method_missing(sym,*args,&b)
#     if sym.to_s[-1..-1] == '='
#       self.addl_ops[sym.to_s[0..-2]] = args.first
#     else
#       super
#     end
#   end
# end
# 
# 
# class Dataload
#   extend ActiveModel::Naming
#   def to_key
#     nil
#   end
#   def persisted?
#     false
#   end
# end