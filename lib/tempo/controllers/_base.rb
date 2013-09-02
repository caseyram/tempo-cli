module Tempo
  module Controllers
    class Base
      class << self

        def filter_projects_by_title( options, args )
          projects = Model::Project
          if options[:exact]
            match = reassemble_the args
            match = [match]
            model_match projects, match, "title", :exact
          else
            model_match projects, args, "title", :fuzzy
          end
        end

        # Takes an array of source strings
        # and filters them down to the ones
        # that match positively against every
        # member of the matches array
        #
        def fuzzy_match( haystack, matches, attribute="id" )

          matches = [matches] unless matches.is_a? Array

          if haystack.is_a? Array
            fuzzy_array_match( haystack, matches )

          elsif haystack.superclass == Model::Base
            model_match( haystack, matches, attribute )
          end
        end

        # Gli default behavior: When args are sent in a
        # command without quotes, they are broken into an array,
        # and the first block is passed to a flag if present.
        # Here we reassemble the string, and add value stored in
        # a flag in the front. The value is also added to the original array

        def reassemble_the( args, flag=nil )
          assembled = ""
          args.unshift flag if flag
          args.each { |a| assembled += " #{a}" }
          assembled.strip!
        end

        private

        # TODO: escape regex characters ., (), etc.
        def match_to_regex( match, type=:fuzzy )
          if type == :exact
            /^#{match}$/
          else
            /#{match}/
          end
        end

        def fuzzy_array_match( haystack, matches )
          results = []
          matches.each do |m|
            reg = match_to_regex m
            haystack.each do |h|
              results << h if reg.match h
            end
            haystack = results
            results = []
          end
          haystack
        end

        def model_match( haystack, matches, attribute, type=:fuzzy )
          attribute = "@#{attribute}".to_sym
          contenders = haystack.index
          results = []
          matches.each do |m|
            reg = match_to_regex m, type
            contenders.each do |c|
              results << c if reg.match c.instance_variable_get(attribute).to_s
            end
            contenders = results
            results = []
          end
          contenders
        end
      end
    end
  end
end