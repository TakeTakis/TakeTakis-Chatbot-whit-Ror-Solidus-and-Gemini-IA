require 'net/http'
require 'json'
require 'uri'


class QuestionsController < ApplicationController
    def create
      
      # Using the global GEMINI_CLIENT constant initialized in the initializer
      contents = {
        contents: {
          role: 'user',
          parts: {
            text: "Eres un asistente en el siguiente proyecto: Creación de una aplicación de comercio electrónico en Ruby on Rails con Solidus e integración de Chatbot con Avatar. Aquí está su pregunta:\n\n#{question}" # Prompt inicial más la pregunta del usuario
          }
        }
      }
  
      # Variable to accumulate the streamed response
      @answer = ""
  
      # Define the block to handle streaming
      stream_proc = Proc.new do |part_text, _event, _parsed, _raw|
        @answer += part_text  # Append each part of the response to @answer
      end
  
      # Send the question to Gemini AI with streaming enabled
      GEMINI_CLIENT.stream_generate_content(contents, model: 'gemini-1.5-flash', stream: true, &stream_proc)

      # Rails.logger.error("Si llegamos")
      #############################################
      generate_avatar_audio(@answer)  # Generate audio after getting the answer
      #############################################




      # Respond with Turbo Stream or HTML (if Turbo Stream fails)
      respond_to do |format|
        format.turbo_stream  # Renders a turbo_stream response
        format.html { redirect_to questions_path, notice: 'Answer was successfully generated.' }
      end
  
    rescue => e
      @answer = "Error: #{e.message}"
      Rails.logger.error("Gemini AI Error: #{e.message}")
    end
  
    private
  
    # Extracts the question parameter from the form
    def question
      params[:question][:question]
    end

    #############################################
    def generate_avatar_audio(answer_text)
      url = URI("https://api.d-id.com/talks")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
  
      request = Net::HTTP::Post.new(url)
      request["accept"] = 'application/json'
      request["content-type"] = 'application/json'
      request["authorization"] = 'Basic TWpBME5qQXlOakpBWTI5c2FXMWhMblJsWTI1dExtMTQ6WW1iNWJ1UlBYOEVfM0hfdnRIcWF6OlltYjVidVJQWDhFXzNIX3Z0SHFheg'

      request.body = {
        "source_url": "https://img.freepik.com/foto-gratis/modelo-mujer-atractiva-mirando-interes-al-frente-sonriendo-expresando-felicidad-haciendo-eleccion-pie-pared-blanca_176420-42619.jpg",
        "script": {
            "type": "text",
            "input": answer_text,
            "provider": {
                "type": "microsoft",
                "voice_id": "es-MX-DaliaNeural"
            }
        }
      }.to_json
      
      response = http.request(request)
      Rails.logger.error("Video generation response: #{response.read_body}")
      # puts response.read_body
      response_body = JSON.parse(response.body)
      Rails.logger.error("Hello Terminal id ?: #{response_body["id"]}\n")
      
      sleep(5) 

      if response_body["id"].present?

        url = URI("https://api.d-id.com/talks/#{response_body["id"]}")

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(url)
        request["accept"] = 'application/json'
        request["authorization"] = 'Basic TWpBME5qQXlOakpBWTI5c2FXMWhMblJsWTI1dExtMTQ6WW1iNWJ1UlBYOEVfM0hfdnRIcWF6OlltYjVidVJQWDhFXzNIX3Z0SHFheg'

        response = http.request(request)
        response_body2 = JSON.parse(response.body)

        Rails.logger.error("HEEEEEEEEEE: #{response_body2}\n")
        Rails.logger.error("HOLAAAAAAAA: #{response_body2["audio_url"]}\n")
        Rails.logger.error("NOOOOOOOOOO: #{response_body2["result_url"]}\n")
        @audio_url = response_body2["audio_url"] # URL del video generado
        @video_url = response_body2["result_url"] # URL del video generado

      else
        Rails.logger.error("No se generó un ID para el video.")
        @answer = "No se pudo generar el video. Por favor, intenta nuevamente."
      end

    end
    #############################################


  end
  