# encoding: utf-8
require File.expand_path("../../spec_helper", __FILE__)

module Redrack
  describe Session do

    it "is valid rack middleware" do
      get "/"
      last_response.should be_ok
    end

  end
end
