module Mes
  module Elastic
    class Model
      module MappingDsl
        DATETIME_FORMAT = 'yyyy-MM-dd HH:mm:ss ZZ'.freeze

        def current_mapping
          @current_mapping ||= {}
        end

        def field?(key)
          current_mapping.key? key.to_sym
        end

        def field(field_name, opts = {})
          field_name = field_name.to_sym
          return if field?(field_name)

          validate_name!(field_name)
          current_mapping[field_name] = transform_mapping(opts)
          run_callback(:after_field_defined, field_name)
        end

        # INFO: as a desired feature it would be nice
        #       to have extra checks for setters of arrays
        def array(field_name, opts = {}, &block)
          if opts[:type] == :object
            object(field_name, array: true, &block)
          else
            field(field_name, opts, &block)
          end
        end

        def object(field_name, opts = {}, &block)
          field_name = field_name.to_sym
          return if field?(field_name)

          validate_name!(field_name)
          current_mapping[field_name] = { properties: catch_object_mapping(field_name, &block), array: opts.fetch(:array, false) }
          run_callback(:after_object_defined, field_name, current_mapping[field_name])
        end

        def multilang_field(name, opts)
          full_path = current_mapping_path + [name]
          root_mapping[:dynamic_templates] << {
            "#{full_path.join('_')}_multilang" => {
              match:   "#{full_path.join('.')}.*",
              mapping: opts
            }
          }
          object name do
            field :default, opts
          end
        end

        private

        def catch_object_mapping(path_name, &block)
          ObjectFieldDefiner.new(root_mapping, current_mapping_path + [path_name]).tap do |definer|
            definer.instance_eval(&block)
          end.current_mapping
        end

        def validate_name!(name)
          raise NotImplementedError
        end

        def run_callback(callback_name, *args)
          send(callback_name, *args) if respond_to?(callback_name, true)
        end

        def transform_mapping(type_or_opts)
          type_or_opts = { type: type_or_opts } unless type_or_opts.is_a?(Hash)

          if type_or_opts[:type] == :datetime
            type_or_opts[:type] = :date
            type_or_opts[:format] = DATETIME_FORMAT
          end

          type_or_opts
        end
      end
    end
  end
end
