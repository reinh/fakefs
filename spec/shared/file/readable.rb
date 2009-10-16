shared_examples_for 'file_readable' do
  before :each do
    @file = 'i_exist'
    @file2 = "/etc/passwd"
    Dir.mkdir "/etc"
    FileUtils.touch(@file2)
  end

  after :each do
    File.delete(@file) if File.exists?(@file)
  end

  it "returns true if named file is readable by the effective user id of the process, otherwise false" do
    @object.send(@method, @file2).should == true
    File.open(@file,'w') { @object.send(@method, @file).should == true }
  end

  it "accepts an object that has a #to_path method" do
    pending "Ruby 1.9"
    @object.send(@method, mock('to_path', :to_path => @file2)).should == true
  end
end

shared_examples_for 'file_readable_missing' do
  it "returns false if the file does not exist" do
    @object.send(@method, 'fake_file').should == false
  end
end
