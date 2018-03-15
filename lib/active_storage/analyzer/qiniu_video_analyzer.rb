module ActiveStorage
  # Extracts the following from a video blob:
  #
  # * Width (pixels)
  # * Height (pixels)
  # * Duration (seconds)
  # * Aspect ratio
  #
  # Example:
  #
  #   ActiveStorage::Analyzer::QiniuVideoAnalyzer.new(blob).metadata
  #   # => {:width=>240, :height=>240, :duration=>"2.000000", :aspect_ratio=>"1:1"}
  #
  class Analyzer::QiniuVideoAnalyzer < Analyzer
    def self.accept?(blob)
      blob.video?
    end

    def metadata
      w, h = width, height
      w, h = h, w if rotated
      {width: w, height: h, duration: duration, aspect_ratio: aspect_ratio}.compact
    rescue
      {}
    end

    private

    def rotated
      @rotated ||= begin
        tags = video_stream['tags']
        tags.is_a?(Hash) && ['90', '-90'].include?(tags['rotate'])
      end
    end

    def width
      video_stream['width']
    end

    def height
      video_stream['height']
    end

    def duration
      video_stream['duration']
    end

    def aspect_ratio
      video_stream['display_aspect_ratio']
    end

    def streams
      @streams ||= begin
        code, result, res = Qiniu::HTTP.api_get(blob.service.url(blob.key, fop: 'avinfo'))
        result['streams']
      end
    end

    def video_stream
      @video_stream ||= streams.detect { |stream| stream["codec_type"] == "video" } || {}
    end
  end
end
