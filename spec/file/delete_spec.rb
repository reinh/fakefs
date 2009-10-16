require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/shared/unlink'

describe "File.delete" do
  before { @method = :delete }
  it_should_behave_like('file_unlink')
end
