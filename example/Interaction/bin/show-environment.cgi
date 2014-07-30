#!/usr/bin/env ruby

require 'cgi'
require 'erb'

cgi = CGI.new

TEMPLATE = <<-HTML
<!DOCTYPE html>
<html>
  <header>
    <title>CGI Execution</title>
  </header>
  <body>
    <h1>CGI Execution</h1>

    <section>
      <h2>Arguments</h2>
      <ol>
        <% ARGV.each do |val| %>
          <li><%= CGI.escapeHTML(val) %></li>
        <% end %>
      </ol>
    </section>

    <section>
      <h2>Parameters</h2>
      <div><%= CGI.escapeHTML(cgi.params.to_s) %></div>
    </section>

    <section>
      <h2>ENV</h2>
      <dl>
      <% ENV.keys.sort.each do |key| %>
        <dt><%= CGI.escapeHTML(key) %></dt><dd><%= CGI.escapeHTML(ENV[key]) %></dd>
      <% end %>
      </dl>
    </section>
  </body>
</html>
HTML

cgi.out(type: "text/html") do
  ERB.new(TEMPLATE).result
end
