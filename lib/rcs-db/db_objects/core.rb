require 'mongoid'

#module RCS
#module DB

class Core
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :version, type: Integer
  field :_grid, type: Array
  field :_grid_size, type: Integer

  index :name
  
  store_in :cores

  after_destroy :destroy_callback

  def destroy_callback
    # remove the content from the grid
    RCS::DB::GridFS.delete self[:_grid].first unless self[:_grid].nil?
  end
end


#end # ::DB
#end # ::RCS