FROM ruby
RUN apt-get update
WORKDIR /bitcoinwalet
COPY Gemfile* /bitcoinwalet/
RUN gem install bundler && bundle install --jobs=3 --retry=3
COPY script.rb /bitcoinwalet/script.rb
RUN chmod +x /bitcoinwalet/script.rb
CMD ["ruby", "script.rb"]
