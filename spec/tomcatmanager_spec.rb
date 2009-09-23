# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fakeweb'

describe "Tomcatmanager" do
  

  before(:each) do
    @account = "manager"
    @incorrect_account = "incorrect"
    @password = "password"
    @host = "127.0.0.1"
    @port = "8080"

    FakeWeb.register_uri(:get, "http://#{@incorrect_account}:#{@password}@#{@host}:#{@port}/manager/list", :body => "Unauthorized", :status => ["401", "Unauthorized"])

    FakeWeb.register_uri(:get, "http://#{@account}:#{@password}@#{@host}:#{@port}/manager/list",
                         :body => <<END_OF_RESPONSE
OK - バーチャルホスト localhost のアプリケーション一覧です
/:running:0:ROOT
/manager:running:3:manager
/hudson:running:0:hudson
/apache-solr-nightly:running:0:apache-solr-nightly
/docs:running:0:docs
/examples:running:0:examples
/host-manager:running:0:host-manager
/solr-search-example:running:0:solr-search-example
END_OF_RESPONSE
                         )

  end

  after(:each) do
    FakeWeb.clean_registry
  end

  it "has account info" do
    tm = TomcatManager.new do |tm|
      tm.manager="manager"
      tm.password="password"
    end
    tm.manager.should == "manager"
    tm.password.should == "password"
  end

  it "has list info after called list method accessed by correct password" do

    tomcat = TomcatManager.new do |tm|
      tm.manager=@account
      tm.password=@password
    end

    list = tomcat.list

    list.first[:path].should == "/"
    list.size.should == 8
  end
  
  it "throw unauthorized exception accessed by incorrect password" do

    tomcat = TomcatManager.new do |tm|
      tm.manager=@incorrect_account
      tm.password=@password
    end

    lambda{tomcat.list}.should raise_error(TomcatManager::Unauthorized)

  end

  it "throw FileNotFound at deploy method with not exist war" do
    tomcat = TomcatManager.new do |tm|
      tm.manager=@account
      tm.password=@password
    end
    
    lambda{ tomcat.deploy "/tmp/aaaaaaaa.war","testpath" }.should raise_error(TomcatManager::WarNotFound)
  end

  it "throw ArgumentError by request method without :get or :put" do
    lambda{ TomcatManager.new.request("/test",:invalid_method) }.should raise_error(ArgumentError)
  end

end
