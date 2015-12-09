require 'slack'
require "exifr"
require "open-uri"
require "json"
TOKEN=ARGV[0]

Slack.configure do |config|
  config.token = TOKEN
end

usrs = Slack.users_list
user ={}
usrs["members"].each{|u|
  user[u["id"]]=u["name"]
}
icon={}

usrs["members"].each{|u|
  icon[u["id"]]=u["profile"]["image_48"]
}

get =  Slack.files_list(page: 1)
num = get["paging"]["pages"].to_i

gpshistory = []
num.times do |pagenum|
  get =  Slack.files_list(page: pagenum+1) unless pagenum==0
  files = get["files"]
  files.each{|f|
    if f["url_download"].to_s[-3,3] == "jpg"
      puts (pagenum+1).to_s + ":" + user[f["user"]]
      open(f["url_download"]) do |data|
        begin
          @exif = EXIFR::JPEG.new(data)
          unless @exif.gps.nil?
            gps = {}
            gps["src"]=f["url_download"]
            gps["user"]=user[f["user"]]
            gps["date"]=@exif.exif.date_time_original unless @exif.exif.date_time_original.nil?
            gps["latitude"]=@exif.gps.latitude
            gps["longitude"]=@exif.gps.longitude
            gps["icon"]=icon[f["user"]]
            gpshistory.push(gps)
            # puts gps.to_json
            puts user[f["user"]]
            puts @exif.exif.date_time_original unless @exif.exif.date_time_original.nil?
            puts @exif.gps.latitude
            puts @exif.gps.longitude

            open("gpshistory.json", 'w') do |io|
              JSON.dump(gpshistory, io)
            end
          end
        rescue
        end
      end
    end
    #`wget #{f["url_download"]} -P files` if f["url_download"].to_s[-3,3] == "jpg"
  }
end
