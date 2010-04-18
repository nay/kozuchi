# SubResources
module ActionController
  module Resources

    class Resource
      def initialize_with_sub_resources(entities, options)
        @sub = !!options.delete(:sub)
        initialize_without_sub_resources(entities, options)
      end

      def sub?
        @sub
      end

      def nesting_path_prefix_for_sub_resources
        @nesting_path_prefix_for_sub_resources ||= "#{shallow_path_prefix}/#{path_segment}/:id"
      end

      def member_path_with_sub_resources
        return member_path_without_sub_resources unless sub?
        @member_path ||= "#{shallow_path_prefix}/#{path_segment}/:#{singular}_id"
      end

      alias_method_chain :initialize, :sub_resources
      alias_method_chain :member_path, :sub_resources
    end

    class SingletonResource < Resource #:nodoc:
      def nesting_path_prefix_for_sub_resources
        @nesting_path_prefix_for_sub_resources ||= "#{shallow_path_prefix}/#{path_segment}"
      end
    end

    private

    def map_sub_resources(entities, singleton, options = {})
      sub_resources = options.delete(:sub_resources)
      if sub_resources
        resource = parent_resource(entities, singleton, options)
        with_options :controller => resource.controller, :path_prefix => resource.nesting_path_prefix_for_sub_resources, :name_prefix => resource.nesting_name_prefix do |map|
          case sub_resources
          when Hash
            sub_resources.keys.each do |sub_entities|
              map.map_resource(sub_entities, sub_resources[sub_entities].merge({:sub => true}))
            end
          when Array
            sub_resources.each do |sub_entities|
              map.map_resource(sub_entities, :sub => true)
            end
          else
            sub_entities = sub_resources
            map.map_resource(sub_entities, :sub => true)
          end
        end
      end
    end

    def map_sub_singleton_resource(entities, singleton, options = {})
      sub_resource = options.delete(:sub_resource)
      if sub_resource
        resource = parent_resource(entities, singleton, options)
        with_options :controller => resource.controller, :path_prefix => resource.nesting_path_prefix_for_sub_resources, :name_prefix => resource.nesting_name_prefix do |map|
          case sub_resource
          when Hash
            sub_resource.keys.each do |sub_entities|
              map.map_singleton_resource(sub_entities, sub_resource[sub_entities].merge({:sub => true}))
            end
          when Array
            sub_resource.each do |sub_entities|
              map.map_singleton_resource(sub_entities, :sub => true)
            end
          else
            sub_entities = sub_resource
            map.map_singleton_resource(sub_entities, :sub => true)
          end
        end
      end
    end

    def parent_resource(entities, singleton, options)
      singleton ? SingletonResource.new(entities, options.dup) : Resource.new(entities, options.dup) # Don't break options
    end

    def map_resource_with_sub_resources(entities, options = {}, &block)
      map_sub_resources(entities, false, options)
      map_sub_singleton_resource(entities, false, options)
      map_resource_without_sub_resources(entities, options, &block)
    end

    def map_singleton_resource_with_sub_resources(entities, options = {}, &block)
      map_sub_resources(entities, true, options)
      map_sub_singleton_resource(entities, true, options)
      map_singleton_resource_without_sub_resources(entities, options, &block)
    end

    def map_collection_actions_with_plural_edit_support(map, resource)
      resource.collection_methods.each do |method, actions|
        actions.each do |action|
          [method].flatten.each do |m|
            case action.to_s
            when "update_all", "destroy_all"
              map_resource_routes(map, resource, action, "#{resource.path}", "#{resource.name_prefix}#{resource.plural}", m)
            when "edit_all"
              map_resource_routes(map, resource, action, "#{resource.path}#{resource.action_separator}edit", "edit_#{resource.name_prefix}#{resource.plural}", m)
            else
              map_resource_routes(map, resource, action, "#{resource.path}#{resource.action_separator}#{action}", "#{action}_#{resource.name_prefix}#{resource.plural}", m)
            end
          end
        end
      end
    end

    def action_options_for_with_sub_resources(action, resource, method = nil, resource_options = {})
      default_options = action_options_for_without_sub_resources(action, resource, method, resource_options)
      if resource.sub?
        default_options[:action] = sub_action_name_for(default_options[:action], resource)
      end
      default_options
    end

    def sub_action_name_for(base_action_name, resource)
      case base_action_name
      when "index"
        resource.plural
      when "edit_all", "update_all", "destroy_all"
        "#{base_action_name.gsub(/_all$/, '')}_#{resource.plural}"
      when "show"
        resource.singular
      else
        "#{base_action_name}_#{resource.collection_methods.values.flatten.include?(base_action_name.to_sym) ? resource.plural : resource.singular}"
      end
    end


    alias_method_chain :action_options_for, :sub_resources
    alias_method_chain :map_resource, :sub_resources
    alias_method_chain :map_singleton_resource, :sub_resources
    alias_method_chain :map_collection_actions, :plural_edit_support
  end
end
