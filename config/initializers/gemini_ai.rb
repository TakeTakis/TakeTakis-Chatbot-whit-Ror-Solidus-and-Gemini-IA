require 'gemini-ai'

# Configure the Gemini AI client with your API key
GEMINI_CLIENT = GeminiAi::Client.new(api_key = ENV['GEMINIS_API_KEY'])