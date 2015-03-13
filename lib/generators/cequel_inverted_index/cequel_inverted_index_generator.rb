class CequelInvertedIndexGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :model, type: :string
  argument :column, type: :string

  def normalize_arguments_and_setup_class_variables
    @model_name = model.underscore
    @column_name = column.underscore
    @model_class_name = @model_name.camelize
    @index_model_name = "#{@model_class_name}#{@column_name.camelize}Index"
    @model_path = "app/models/#{@model_name}.rb"
  end

  def announce
    say("Creating Inverse Index for Column: #{@column_name} on Model: #{@model_class_name}", :cyan)
  end

  def verify_model_and_column_present
    unless File.exist?(@model_path)
      say("Error: file #{@model_path} not found", :red)
      raise Thor::Error
    end

    class_pattern = /^\s*class #{@model_class_name}\s*$/
    model_file_content = File.read(@model_path)
    unless model_file_content =~ class_pattern
      say("Error: Model #{@model_class_name} not found", :red)
      raise Thor::Error
    end

    column_pattern = /^\s*column\s+:#{@column_name}/
    unless model_file_content =~ column_pattern
      say("Error: Column #{@column_name} not found on model #{@model_class_name}", :red)
      raise Thor::Error
    end

    say("File, model and column detected sucessfully", :green)
  end

  def create_index_model
    template("index_model.rb.erb", "app/models/#{@model_name}_#{@column_name}_index.rb")
    copy_file("inverted_index.rb", "app/models/concerns/inverted_index.rb")
  end

  def extend_target_model
    template("target_model.rb.erb", "app/models/concerns/#{@column_name}_search.rb")
    insert_into_file(@model_path, "  include #{@column_name.camelize}Search\n", {after: "include Cequel::Record\n"} )
  end

  def create_reindexing_rake_task
    template("reindex.rake.erb", "lib/tasks/reindex_#{@model_name}_#{@column_name}_index.rake")
  end

  def parting_shot
    say("Looks like everything went ok.", :cyan)
    say("You might want to look at file #{@model_path} to make sure I didn't trash it.", :cyan)
    say("If it looks ok, run `rake:cequel:migrate` to create your inverted index.", :cyan)
    say("Note that if you already had records in the database, the new index won't know about those, and you will need to reindex.", :cyan)
    say("You can reindex your new index by executing:", :cyan)
    say("\t`rake cequel:reindex_#{@model_name}_#{@column_name}_index, but be cautious if you have a large database.", :cyan)
    say("Your model #{@model_class_name} now has the following new class methods:", :cyan)
    say("\tfind_all_by_#{@column_name}(val)", :cyan)
    say("\tany_with_#{@column_name}?(val)", :cyan)
    say("\tcount_with_#{@column_name}(val)", :cyan)
  end
end
