shared_examples_for 'file_writable' do
  before :each do
    @file = 'i_exist'
    Dir.mkdir('/etc')
    File.new('/etc/passwd', 'w', 0000)
  end

  after :each do
    File.delete(@file) if File.exists?(@file)
  end

  it "returns true if named file is writable by the effective user id of the process, otherwise false" do
    @object.send(@method, "/etc/passwd").should == false
    File.open(@file,'w') { @object.send(@method, @file).should == true }
  end

    it "accepts an object that has a #to_path method" do
      pending "Ruby 1.9"
      File.open(@file,'w') { @object.send(@method, mock_to_path(@file)).should == true }
    end
end

describe :file_writable_missing, :shared => true do
  it "returns false if the file does not exist" do
    @object.send(@method, 'fake_file').should == false
  end
end
