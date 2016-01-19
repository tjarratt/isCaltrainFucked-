require 'sentimental'
require 'twitter'

module TwitterHelper
  def twitter_sentiment
    analyzer = Sentimental.new
    search_results = twitter_client.search('caltrain',
      :count => 10,
      :recent_type => 'recent',
    )
    search_results.attrs[:search_metadata][:next_results] = nil

    tweets = search_results.map(&:text).map {|t| [t, analyzer.get_score(t)] }

    return {
      :tweets => tweets,
      :sum => tweets.map(&:last).inject(:+),
      :fatality => tweets.any? {|t| t.first.downcase.match(/fatal/) || t.first.downcase.match(/death/)},
      :disruption => tweets.any? {|t| t.first.downcase.match /disruption/ },
      :delay => tweets.any? {|t| t.first.downcase.match /delay/ }
    }
  end
end
