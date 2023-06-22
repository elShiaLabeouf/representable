require 'representable'
require 'representable/object/binding'

module Representable
  module Object
    autoload :Collection, 'representable/object/collection'

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        register_feature Representable::Object
      end
    end


    module ClassMethods
      def format_engine
        Representable::Object
      end

      def collection_representer_class
        Collection
      end

      def cache_struct
        @represented_struct ||= Struct.new(*representable_attrs.keys.map(&:to_sym))
      end

      def cache_wrapper_struct(wrap:)
        struct_name = :"@_wrapper_struct_#{wrap}"
        return instance_variable_get(struct_name) if instance_variable_defined?(struct_name)

        instance_variable_set(struct_name, Struct.new(wrap))
      end
    end

    def from_object(data, options={}, binding_builder=Binding)
      update_properties_from(data, options, binding_builder)
    end

    def to_object(options={}, binding_builder=Binding)
      represented_struct = self.class.cache_struct

      object = create_representation_with(represented_struct.new, options, binding_builder)
      return object if options[:wrap] == false
      return object unless (wrap = options[:wrap] || representation_wrap(options))

      wrapper_struct = self.class.cache_wrapper_struct(wrap: wrap.to_sym)
      wrapper_struct.new(object)
    end

  end
end
