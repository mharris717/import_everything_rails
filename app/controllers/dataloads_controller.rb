class DataloadsController < InheritedResources::Base
  belongs_to :workspace
  def run
    @dataload = resource
    @dataload.run!
    redirect_to [@dataload.workspace,@dataload]
  end
  
end