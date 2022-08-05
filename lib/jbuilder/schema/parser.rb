require 'safe_parser'

module JbuilderSchema
  class Parser
    attr_reader :source

    def initialize(source)
      @source = source

      Zeitwerk::Loader.eager_load_all if defined?(Zeitwerk::Loader)
    end

    def parse!(*args)
      _create_schema!
    end

    private

    def _lines
      source.to_s
            .split(/\n+|\r+/)
            .reject(&:empty?)
            .reject { |l| l.start_with?('#') }
            .map { |l| l.split('#').first }
    end

    def _parse_lines!
      schema_regexp = ",?\s?schema(:|=>|\s=>)\s?"
      hash_regexp = "{(.*?)}"

      {}.tap do |hash|
        _lines.each_with_index do |line, index|
          hash[index] = {}.tap do |line_hash|
            line_hash[:property] = line.split.first.delete_prefix('json.')
            schema = line.slice!(/#{schema_regexp + hash_regexp}/)&.strip&.gsub(/#{schema_regexp}/, '') || '{}'
            line_hash[:schema] = SafeParser.new(schema).safe_load
            line_hash[:arguments] = line.split[1..-1].map { |e| e.gsub(',', '') }
            line_hash[:schema] = _schema_for_line(line_hash)
          end
        end
      end
    end

    def _schema_for_line(line)
      schema = line[:schema]
      unless schema[:type]
        schema[:type] = _get_type(line[:arguments].first)
      end
      schema
    end

    def _get_type(value)
      begin
        eval(value).class.name.downcase.to_sym
      rescue NoMethodError
        _find_type(value)
      end

    end

    def _find_type(string)
      variable, method = string.split('.')
      ObjectSpace.each_object(Class)
                 .select { |c| c.name == variable.gsub('@', '').classify }.first
                 .columns_hash[method].type
    end

    def _create_schema!
      sorted_hash = _parse_lines!.sort.to_h

      {}.tap do |hash|
        sorted_hash.each do |_index, line|
          hash[line[:property]] = line[:schema]
        end
      end
    end
  end
end
