require "scoped_search"

ActiveRecord::Base.class_eval do
  def self.inherited(child)
    super
    if child.column_names.include?("deleted_at")
      child.class_eval do
        scope :without_deleted, where(:deleted_at => nil)
        scope :with_deleted, where("\"#{self.table_name}\".\"deleted_at\" IS NULL OR \"#{self.table_name}\".\"deleted_at\" IS NOT NULL")

        def deleted?
          !!deleted_at
        end

        def destroy(force=false)
          if force
            super()
          else
            update_attribute(:deleted_at, Time.now)
          end
        end

      end
    end

    if child.column_names.include?("archived_at")
      child.class_eval do
        scope :without_archived, where(:archived_at => nil)
        scope :with_archived, where("\"#{self.table_name}\".\"archived_at\" IS NULL OR \"#{self.table_name}\".\"archived_at\" IS NOT NULL")

        def archived?
          !!archived_at
        end

        def toggle_archive!
          self.archived_at = archived? ? nil : Time.now
          self.save
          archived_at
        end
      end
    end
  end
end


class ScopedSearch
  module Model
    module ClassMethods
      def scoped_search(options={})
        options = (options || {}).stringify_keys
        %w(archived deleted).each do |column_name|
          if self.column_names.include?("#{column_name}_at")
            unless ::ActiveRecord::ConnectionAdapters::Column.value_to_boolean(options["with_#{column_name}"])
              options["without_#{column_name}"] = true
            end
          end
        end
        ScopedSearch::Base.new(self, options)
      end
    end
  end
end
