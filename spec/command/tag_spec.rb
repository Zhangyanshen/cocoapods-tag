require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Tag do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ tag }).should.be.instance_of Command::Tag
      end
    end
  end
end

