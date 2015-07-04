require 'sinatra'
require 'tumblr_client'
require 'dotenv'
require 'active_support/core_ext/object/to_query'
Dotenv.load

helpers do
  LIMIT = 20

  def tumblr
    @tumblr ||= Tumblr::Client.new({
      consumer_key: ENV['TUMBLR_CONSUMER_KEY'],
      consumer_secret: ENV['TUMBLR_CONSUMER_SECRET'],
      oauth_token: ENV['TUMBLR_OAUTH_TOKEN'],
      oauth_token_secret: ENV['TUMBLR_OAUTH_TOKEN_SECRET']
    })
  end

  def page
    params[:page] ||= 1
    params[:page].to_i
  end

  def page_path(domain, page)
    "/?" + {domain: domain, page: page}.to_query
  end

  def prev_page
    if (page - 1) * LIMIT > 0
      page_path(params[:domain], page - 1)
    else
      nil
    end
  end

  def next_page
    if (page + 1) * LIMIT < posts['total_posts']
      page_path(params[:domain], page + 1)
    else
      nil
    end
  end

  def posts
    @posts ||= tumblr.posts(params[:domain], type: 'text', limit: LIMIT, offset: LIMIT*(page-1))
  end
end

get '/' do
  if params[:format] == 'json'
    content_type 'application/json'
    posts.to_json
  else
    haml :app
  end
end

post '/' do
  text = params[:text]
  if text.match(URI.regexp)
    domain = URI.parse(text).host
  elsif text.match(/^[a-zA-Z0-9\-]+$/)
    domain = "#{text.downcase}.tumblr.com"
  else
    domain = text
  end
  redirect page_path(domain, 1)
end

__END__
@@ app
!!! html
%html
  %head
    %meta{charset:'utf-8'}
    %meta{name:'viewport',content:'width=device-width,initial-scale=1.0'}
    %title= params[:domain] ? "#{posts['blog']['title']} - prgrphs2" : 'prgrphs2'
    %link{rel:'stylesheet',href:'//maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css'}
    %link{rel:'stylesheet',href:'/stylesheets/app.css'}
  %body
    .container
      - if params[:domain]
        - posts['posts'].each do |post|
          .post
            .post-link
              %a{href:post['post_url']}
                %img{src:'/images/link.gif'}
            - if post['title']
              .post-title= post['title']
            .post-body= post['body']
        .pagination.text-center
          - if prev_page
            %a{href: prev_page} <<
          - if next_page
            %a{href: next_page} >>
      - else
        .post
          %form.form{method:'POST'}
            %input.form-control{type:'text',name:'text',placeholder:'username or url ...'}
