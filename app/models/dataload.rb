# class MockFile
#   attr_accessor :filename, :read
#   include FromHash
# end

class Dataload
  include MongoMapper::Document
  plugin Joint
  attachment :file
  key :coll_name
  belongs_to :workspace
end

class Dataload
  key :addl_ops, Hash
  def method_missing(sym,*args,&b)
    if sym.to_s[-1..-1] == '='
      self.addl_ops[sym.to_s[0..-2]] = args.first
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