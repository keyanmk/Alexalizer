#A very basic movie sentiment analyzer for twitter.
class MovieSentiment
  require 'httpclient'
  require 'json'
  require "will_paginate"
  
  
  def self.twitter_results query,page
    #page = page.to_i + 1
    url = "http://search.twitter.com/search.json?phrase=#{query}&rpp=100&page=#{page}&lang=en"
    server = HTTPClient.new
    url = URI.escape(url)
    respoll = server.get(url)
    str = ""
    #@respoll = respoll
    res_stat = respoll.status
    #@stat = res_stat
    if res_stat == 200
      return ActiveSupport::JSON.decode(respoll.content)      
    else
      return nil
    end 
  end
  
  def self.clean text
    text = text.to_s().gsub('\\',"")
    return text
  end
 
 #Returns the  sentiment in the given tweet for the movie 
  def self.sentiment( movie_name, tweet)
    text = tweet.to_s()
    text.downcase!
    text.to_s().gsub! "'"," "
    text.to_s().gsub! /[^\w\-]/, ' ' 
    #Does all the parsing and returns the sentiment
    return Movie.alexalyzer(movie_name, text)
  end
  
  
  def self.try_nailing(movie_name)
    nailers = Array.new
    nailers << ["{movie} was awesome","loved "]
  end
  
  def self.alexalyzer(movie_name,tweet)
    i = 0
    alex_value = 0
    
    tweet = tweet.to_s().gsub("#{movie_name.to_s()}","it")
    array_of_words = tweet.to_s().split(" ")
    #iterate through all the words and find the first sentiment word found 
    array_of_words.each{|word|
      sentiment = Sentiment.find(:first, :conditions => {:word => word})
      #if a sentiment has been found then check its polarity
      if sentiment!=nil
        #if the movie name or the term 'movie' is in the vicinity of the positive word
        #then its a positive sentiment
        if sentiment.polarity == "P"
          if ((array_of_words[i-1] == "it") || (array_of_words[i-2] == "it") || (array_of_words[i-3] == "it") || (array_of_words[i-1] == movie_name) || (array_of_words[i-2] == movie_name) || (array_of_words[i-3] == movie_name) || (array_of_words[i+1] == movie_name) || (array_of_words[i+2] == movie_name) || (array_of_words[i-1] == "movie") || (array_of_words[i-2] == "movie") || (array_of_words[i+1] == "movie") ||  (array_of_words[i+2] == movie_name) || (array_of_words[i-1] == "movie") || (array_of_words[i-2] == "movie") || (array_of_words[i-3] == "movie"))
            alex_value = 1
            
            expectation = Expectation.count(:conditions => {:word => [array_of_words[i-3],array_of_words[i-2],array_of_words[i-1],array_of_words[i+1],array_of_words[i+2],array_of_words[i+3]]})
            if expectation.to_i > 1
              alex_value = 0
            else
              #make sure if theres no negative word
              negatives = Sentiment.count(:conditions => {:word => array_of_words, :polarity => 'N'})
              if negatives.to_i < 1
                alex_value = 1
              else
                alex_value = 0
              end
            end
            
            
            
            break
            
          else 
            #fetch the 3 words before the positive sentiment
            #if they are negators then its a negative sentiment
            negator = Negator.find(:first, :conditions => {:word =>["#{array_of_words[i-1].to_s()}","#{array_of_words[i-2].to_s()}","#{array_of_words[i-3].to_s()}"] })
            if negator!=nil
              alex_value = -1
              break
            else
              #THE BETTER THAN RULE
              if ((array_of_words[i] == "better") && (tweet.to_s().include? "better than"))
                
                br_array = tweet.to_s().split("better than")
                # if the movie is found before the text better than
                #then sure as heck its a positive review else if
                # its found in the second half of better half its negative
                #TRY THIS SHIT! IT WORKS
                if br_array[0].to_s().include? movie_name.to_s()
                  alex_value = 1
                elsif br_array[0].to_s().include? movie_name.to_s()
                  alex_value = -1
                else
                  alex_value = 0
                end
                
              end
              
              break
            end
            if alex_value == 0
              alex_value = 1
            end
            break
          end
        else
          #theres a negative keyword somewhere.. 
          if ((array_of_words[i-1] == "it") || (array_of_words[i-2] == "it") ||  (array_of_words[i-1] == movie_name) || (array_of_words[i-2] == movie_name) || (array_of_words[i+1] == movie_name) || (array_of_words[i+2] == movie_name) || (array_of_words[i-1] == "movie") || (array_of_words[i-2] == "movie") || (array_of_words[i+1] == "movie") ||  (array_of_words[i+2] == movie_name) || (array_of_words[i-1] == "movie") || (array_of_words[i-2] == "movie"))
            alex_value = -1
            break
          else
            
            #else if the positive sentiment and the movies
          end
        end
      end
      i = i.to_i + 1
    }
    return alex_value
  end
  

  
  
end
