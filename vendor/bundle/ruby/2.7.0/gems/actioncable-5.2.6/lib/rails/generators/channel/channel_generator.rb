module Rails
  module Generators
    class ChannelGenerator < NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :actions, type: :array, default: [], banner: 'method method'

      class_option :assets, type: :boolean

      check_class_collision suffix: 'Channel'

      def create_channel_file
        template 'channel.rb', File.join('app/channels', class_path, "#{file_name}_channel.rb")

        if options[:assets]
          template 'assets/cable.js', 'app/assets/javascripts/cable.js' if behavior == :invoke

          js_template 'assets/channel', File.join('app/assets/javascripts/channels', class_path, file_name.to_s)
        end

        generate_application_cable_files
      end

      private

      def file_name
        @_file_name ||= super.gsub(/_channel/i, '')
      end

      # FIXME: Change these files to symlinks once RubyGems 2.5.0 is required.
      def generate_application_cable_files
        return if behavior != :invoke

        files = [
          'application_cable/channel.rb',
          'application_cable/connection.rb'
        ]

        files.each do |name|
          path = File.join('app/channels/', name)
          template(name, path) unless File.exist?(path)
        end
      end
    end
  end
end
