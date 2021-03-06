require "spec_helper"

describe Songkick::Transport::Request do
  let :params do
    {:username => "Louis", :password => "CK", :access => {:token => "foo"}}
  end
  
  let :headers do
    {"Authorization" => "Hello"}
  end
  
  let :get_request do
    Songkick::Transport::Request.new("www.example.com", "GET", "/", params, headers)
  end
  
  let :post_request do
    Songkick::Transport::Request.new("www.example.com", "POST", "/", params)
  end
  
  def query(request, pattern)
    request.to_s.scan(pattern).flatten.first.split("&").sort
  end
  
  describe :to_s do
    context "with a get request" do
      it "returns the request as a curl command" do
        pattern = %r{^GET 'www.example.com/\?([^']+)' -H 'Authorization: Hello'$}
        get_request.to_s.should =~ pattern
        query(get_request, pattern).should == ["access[token]=foo", "password=CK", "username=Louis"]
      end
    end
    
    context "with a post request" do
      it "returns the request as a curl command" do
        pattern = %r{^POST 'www.example.com/' -H 'Content-Type: application/x-www-form-urlencoded' -d '([^']+)'$}
        post_request.to_s.should =~ pattern
        query(post_request, pattern).should == ["access[token]=foo", "password=CK", "username=Louis"]
      end
    end
    
    describe "with query sanitization" do
      before do
        Songkick::Transport.stub(:sanitized_params).and_return [/password/, "access[token]", /Authorization/i]
      end

      context "with a get request" do
        it "removes the parameter values from the request" do
          pattern = %r{^GET 'www.example.com/\?([^']+)' -H 'Authorization: \[REMOVED\]'$}
          get_request.to_s.should =~ pattern
          query(get_request, pattern).should == ["access[token]=[REMOVED]", "password=[REMOVED]", "username=Louis"]
        end
      end
      
      context "with a post request" do
        it "removes the parameter values from the request" do
          pattern = %r{^POST 'www.example.com/' -H 'Content-Type: application/x-www-form-urlencoded' -d '([^']+)'$}
          post_request.to_s.should =~ pattern
          query(post_request, pattern).should == ["access[token]=[REMOVED]", "password=[REMOVED]", "username=Louis"]
        end
      end
    end
  end
end

