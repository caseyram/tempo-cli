module Tempo
  module Views
    class << self

      # single project list, build according to options
      #
      def project_view( project, options={})

        if options[:verbose]
          options[:id] = true
          options[:tag] = true
        end
        options[:active] = options.fetch( :active, true )

        id = options[:id] ? "[#{project.id}] " : ""
        active = options[:active] ? active_indicator( project ) : ""
        depth = "  " * options[:depth] if options[:depth]
        title = project.title
        view = "#{id}#{active}#{depth}#{title}"
        tags = options[:tag] || options[:untag] ? tag_view( project.tags, view.length ) : ""
        view += tags
      end

      # list of projects, build according to options
      #
      def projects_list_view( options={} )

        projects = options.fetch( :projects, Tempo::Model::Project.index )
        return no_items( "projects" ) if projects.empty?

        output = options.fetch( :output, true )
        depth = options.fetch( :depth, 0 )
        parent = options.fetch( :parent, :root )

        view = Tempo::Model::Project.sort_by_title projects do |projects|
          view = []
          projects.each do |p|
            if p.parent == parent
              view << project_view( p, options )
              if not p.children.empty?
                child_opts = options.clone
                #child_opts[:projects] = projects
                child_opts[:depth] = depth + 1
                child_opts[:parent] = p.id
                child_opts[:output] = false
                child_array = projects_list_view child_opts
                view.push *child_array
              end
            end
          end
          view
        end

        return_view view, options
      end

      # list of sorted projects, no hierarchy
      def flat_projects_list_view( options={} )
        projects = options.fetch( :projects, Tempo::Model::Project.index )

        view = Tempo::Model::Project.sort_by_title projects do |projects|
          view = []
          projects.each do |p|
            if options[:id]
              view << "[#{p.id}]\t#{active_indicator p}#{p.title}"
            else
              view << "#{active_indicator p}#{p.title}"
            end
          end
          view
        end

        return_view view, options
      end
    end
  end
end
